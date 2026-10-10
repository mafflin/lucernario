import Toybox.Application.WatchFaceConfig;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The watch face: owns the elements. Everything but the seconds is drawn
//! off screen once a minute; an update copies it and adds the seconds hand.
class LucernarioView extends WatchUi.WatchFace {

    //! Shares of the screen height: the line the status row mirrors, and the
    //! data fields' drop below it
    private const FRAME_RATIO = 0.66;
    private const FIELD_DROP_RATIO = 0.02;

    private const BACKGROUND = Graphics.COLOR_BLACK;

    private var timeDisplay as TimeDisplay;
    private var daylight as Daylight;
    private var dayColors as DayColors;
    private var rimMarks as RimMarks;
    private var numerals as RimNumerals;
    private var hourHand as HourHand;
    private var activityTimer as ActivityTimer;
    private var statusBar as StatusBar;
    private var fields as DataFields;
    private var secondsHand as SecondsHand;
    private var goalProgress as GoalProgress;
    private var goalHand as GoalHand;
    private var faceBuffer as FaceBuffer;
    private var editor as Editor;

    //! AMOLED: asleep, only the time shows
    private var needsBurnInProtection as Boolean = false;
    private var isAwake as Boolean = true;

    //! Whether the system lets the seconds move every second in low power
    //! mode; no longer once the power budget is exceeded
    private var partialUpdatesAllowed as Boolean = true;

    //! Whether the native watch face editor started the face
    private var editMode as Boolean;

    //! A data field has a new value the off screen face does not show yet;
    //! only the row is drawn again for it
    private var rowStale as Boolean = false;

    function initialize(editMode as Boolean) {
        WatchFace.initialize();

        self.editMode = editMode;

        timeDisplay = new TimeDisplay();
        daylight = Sun.daylight();
        dayColors = new DayColors(daylight);
        rimMarks = new RimMarks(dayColors);
        numerals = new RimNumerals(dayColors);
        hourHand = new HourHand(dayColors);
        activityTimer = new ActivityTimer();
        statusBar = new StatusBar();
        fields = new DataFields();
        secondsHand = new SecondsHand();
        goalProgress = new GoalProgress();
        goalHand = new GoalHand();
        faceBuffer = new FaceBuffer();
        editor = new Editor(fields);
    }

    //! Size everything for this screen
    function onLayout(dc as Dc) as Void {
        needsBurnInProtection = Clock.settings().requiresBurnInProtection;

        Dial.setup(dc);
        prepareRim(dc);

        faceBuffer.prepare(dc);
        placeFrame(dc);

        // The editor shows a snapshot; live updates are not worth the power.
        // Before the settings: a saved pick then swaps the subscription.
        if (!editMode) {
            subscribeToComplications();
        }

        loadSettings();
    }

    //! editedType is null while initializing
    function updateConfiguration(config as WatchFaceConfig.Settings, editedType as WatchFaceConfigType?) as Void {
        var shown = fields.shownIds();

        editor.apply(config, editedType);

        // Live updates follow the picks; none in the editor.
        if (!editMode) {
            fields.follow(shown);
        }

        applyStyle();
        applyColors();
        redraw();
    }

    //! The drawable the editor is about to pulse, null for none
    function getComplication(complication as ComplicationRef) as ComplicationDrawableRef? {
        var pulsed = editor.pulse(complication);

        if (pulsed != null) {
            redraw();
        }

        return pulsed;
    }

    //! The slot under a tap, or null
    function getTappedComplication(x as Number, y as Number) as Number? {
        return editor.tappedSlot(x, y);
    }

    function onComplicationChange(complicationId as Complications.Id) as Void {
        if (fields.refreshShowing(complicationId)) {
            rowStale = true;
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Dc) as Void {
        // A partial update may have left a clip behind.
        dc.clearClip();
        Clock.read();

        if (isAlwaysOn()) {
            drawAlwaysOn(dc);
            return;
        }

        var face = currentFace();

        if (face != null) {
            dc.drawBitmap(0, 0, face);
        } else {
            drawFace(dc);
        }

        drawSeconds(dc, face != null);
    }

    //! Once a second in low power mode; has to stay within the power budget
    function onPartialUpdate(dc as Dc) as Void {
        if (isAlwaysOn() || !partialUpdatesAllowed) {
            return;
        }

        Clock.readTime();

        // As last drawn, not drawn again: a whole face would eat the budget,
        // and asleep the next full update is up to a minute off. A new data
        // field value redraws only the row.
        var face = faceBuffer.lastDrawn();

        // Nothing to put back under the old seconds.
        if (face == null) {
            return;
        }

        smooth(dc);

        if (rowStale) {
            copyRow(dc, face);
        }

        secondsHand.drawPartial(dc, face);
    }

    //! The seconds would freeze once the system stops calling onPartialUpdate,
    //! so they come off the screen in low power mode instead
    function turnPartialUpdatesOff() as Void {
        partialUpdatesAllowed = false;
        WatchUi.requestUpdate();
    }

    //! Back from another screen: the off screen face may be from before it,
    //! and the fields may have missed updates meanwhile
    function onShow() as Void {
        fields.refreshAll();
        redraw();
    }

    function onEnterSleep() as Void {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    //! The off screen face may be from before the sleep began, and the
    //! fields may have missed updates meanwhile
    function onExitSleep() as Void {
        isAwake = true;
        fields.refreshAll();
        redraw();
    }

    //! The marks size the rest of the rim
    private function prepareRim(dc as Dc) as Void {
        rimMarks.prepare();

        var markReach = rimMarks.reach();
        var markWidth = rimMarks.width();

        numerals.prepare(dc, markReach);
        secondsHand.prepare(markReach, markWidth);
        hourHand.prepare(rimMarks.minorReach());
        goalHand.prepare(markReach, markWidth);
    }

    //! The status row above the time mirrors the line the fields hang from
    private function placeFrame(dc as Dc) as Void {
        var frame = (Dial.screenHeight * FRAME_RATIO).toNumber();
        var top = frame + (Dial.screenHeight * FIELD_DROP_RATIO).toNumber();

        fields.prepare(dc, top);
        statusBar.mirror(frame);
    }

    //! Null without watch face configuration support: the defaults stand
    private function loadSettings() as Void {
        var settings = WatchFaceConfig.getSettings(null);

        if (settings != null) {
            updateConfiguration(settings, null);
        }
    }

    //! The layouts differ only in the rim numerals
    private function applyStyle() as Void {
        numerals.setEnabled(Styles.hasNumerals(editor.style()));
    }

    //! Accent: the hands. Data: the time, the status row and the data
    //! fields, and the rim until the sun is known.
    private function applyColors() as Void {
        var accent = editor.accentColor();
        var data = editor.dataColor();

        secondsHand.setColor(accent);
        hourHand.setColor(accent);
        goalHand.setColor(accent);
        timeDisplay.setColor(data);
        dayColors.setFallbackColor(data);
        statusBar.setColor(data);
        fields.setColor(data);
    }

    //! Something on the off screen face has changed
    private function redraw() as Void {
        faceBuffer.invalidate();
        WatchUi.requestUpdate();
    }

    private function subscribeToComplications() as Void {
        fields.subscribe();
        Complications.registerComplicationChangeCallback(method(:onComplicationChange));
    }

    private function isAlwaysOn() as Boolean {
        return needsBurnInProtection && !isAwake;
    }

    //! Only the time, straight on screen; the buffer is drawn again on waking
    private function drawAlwaysOn(dc as Dc) as Void {
        smooth(dc);
        paintBackground(dc);
        timeDisplay.draw(dc);

        faceBuffer.invalidate();
        secondsHand.forget();
    }

    //! The off screen face, drawn anew when the minute has moved on; null
    //! without room for it
    private function currentFace() as BufferedBitmap? {
        var face = faceBuffer.bitmap();

        if (face == null) {
            return null;
        }

        var minute = Clock.minuteOfDay();

        if (!faceBuffer.isCurrent(minute)) {
            drawFace(face.getDc());
            faceBuffer.markDrawn(minute);
        } else if (rowStale) {
            redrawRow(face);
        }

        return face;
    }

    //! The data fields alone, drawn again on the off screen face; the box
    //! that changed, null for none
    private function redrawRow(face as BufferedBitmap) as Array<Number>? {
        var faceDc = face.getDc();

        rowStale = false;
        smooth(faceDc);

        return fields.redraw(faceDc, editor.pulsedSlot(), BACKGROUND);
    }

    //! The row drawn again off screen, and copied to the screen
    private function copyRow(dc as Dc, face as BufferedBitmap) as Void {
        var box = redrawRow(face);

        if (box == null) {
            return;
        }

        dc.setClip(box[0], box[1], box[2] - box[0], box[3] - box[1]);
        dc.drawBitmap(0, 0, face);
        dc.clearClip();
    }

    //! Everything but the seconds
    private function drawFace(dc as Dc) as Void {
        rowStale = false;
        smooth(dc);
        paintBackground(dc);
        refreshReadings();

        rimMarks.draw(dc);
        numerals.draw(dc, activityTimer.isRunning());
        goalHand.draw(dc);
        hourHand.draw(dc);
        statusBar.draw(dc);
        fields.draw(dc, editor.pulsedSlot());
        timeDisplay.draw(dc);
    }

    //! Asleep, the hand shows only if a partial update can move it, which
    //! takes the off screen face to copy back under it.
    private function drawSeconds(dc as Dc, hasFace as Boolean) as Void {
        if (!isAwake && !(partialUpdatesAllowed && hasFace)) {
            // Nothing on screen to lift off next tick.
            secondsHand.forget();
            return;
        }

        smooth(dc);
        secondsHand.draw(dc);
    }

    //! Everything the draw reads, before anything draws
    private function refreshReadings() as Void {
        if (daylight.refresh()) {
            dayColors.refresh();
        }

        activityTimer.refresh();
        fields.refreshClocked();

        refreshGoal();
    }

    private function refreshGoal() as Void {
        goalProgress.refresh();
        goalHand.setShare(goalProgress.share());
    }

    //! Once per dc: the dc between two updates is the system's
    private function smooth(dc as Dc) as Void {
        dc.setAntiAlias(true);
    }

    private function paintBackground(dc as Dc) as Void {
        dc.setColor(BACKGROUND, BACKGROUND);
        dc.clear();
    }
}
