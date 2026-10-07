import Toybox.Application.WatchFaceConfig;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The watch face: owns the elements and applies the configuration.
class LucernarioView extends WatchUi.WatchFace {

    //! Shares of the screen height: the line the status row mirrors, the
    //! data container's drop below it, and the sun field's below that
    private const FRAME_RATIO = 0.66;
    private const FIELD_DROP_RATIO = 0.02;
    private const SUN_DROP_RATIO = 0.02;

    private const BACKGROUND = Graphics.COLOR_BLACK;

    //! Until the editor has picked a color
    private const DEFAULT_COLOR = Graphics.COLOR_WHITE;

    //! Gates the activity read
    private var activityShown as Boolean = false;

    private var timeDisplay as TimeDisplay;
    private var daylight as Daylight;
    private var sunField as SunField;
    private var dayColors as DayColors;
    private var rimMarks as RimMarks;
    private var numerals as RimNumerals;
    private var secondsHand as SecondsHand;
    private var hourHand as HourHand;
    private var goalHand as GoalHand;
    private var windReading as WindReading;
    private var windBearing as WindBearing;
    private var activityTimer as ActivityTimer;
    private var activityReading as ActivityReading;
    private var recovery as Recovery;
    private var goalProgress as GoalProgress;
    private var statusBar as StatusBar;
    private var centerField as ComplicationField;
    private var fields as Array<ComplicationField>;

    //! Whether the native watch face editor started the face
    private var editMode as Boolean;

    //! What the editor is pulsing, hidden meanwhile
    private var pulsed as WatchUi.Drawable?;

    private var isAwake as Boolean = true;

    //! AMOLED: asleep, only the time shows
    private var needsBurnInProtection as Boolean = false;

    //! Whether the system lets the hand move every second in low power mode
    private var partialUpdatesAllowed as Boolean;

    //! Asked once: a partial update should not look a symbol up every tick
    private var canSmooth as Boolean = false;

    //! Made once: a partial update should not allocate a Method every tick
    private var restoreRimCallback as Method(dc as Dc, second as Number) as Void;

    function initialize(editMode as Boolean) {
        WatchFace.initialize();

        self.editMode = editMode;

        timeDisplay = new TimeDisplay();
        daylight = new Daylight();
        sunField = new SunField(daylight);
        dayColors = new DayColors(daylight);
        rimMarks = new RimMarks(dayColors);
        numerals = new RimNumerals(dayColors);
        secondsHand = new SecondsHand();
        hourHand = new HourHand(dayColors);
        windReading = new WindReading();
        windBearing = new WindBearing(windReading);
        activityTimer = new ActivityTimer();
        activityReading = new ActivityReading();
        recovery = new Recovery();
        goalProgress = new GoalProgress();
        goalHand = new GoalHand(goalProgress);
        statusBar = new StatusBar(windReading);

        centerField = new ComplicationField(SlotId.CENTER, Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY);
        fields = [centerField];

        partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        restoreRimCallback = method(:restoreRim);
    }

    //! Size everything for this screen and load the editor's settings
    function onLayout(dc as Dc) as Void {
        canSmooth = (dc has :setAntiAlias);
        needsBurnInProtection = Clock.settings().requiresBurnInProtection;

        Dial.setup(dc);
        prepareRim(dc);
        placeFields(dc);
        loadSettings();

        // The editor shows a snapshot; live updates are not worth the power.
        if (!editMode) {
            subscribeToComplications();
        }
    }

    //! Apply the editor's settings. editedType is null while initializing.
    function updateConfiguration(config as WatchFaceConfig.Settings, editedType as WatchFaceConfigType?) as Void {
        applyStyle(config.styleId);
        applyAccentColor(config.accentColor);
        applyDataColor(config.complicationColor);
        applyComplications(config.complicationSettings);

        // On to another setting: the container is no longer being pulsed.
        if (editedType != WatchUi.WATCH_FACE_CONFIG_TYPE_COMPLICATION) {
            pulsed = null;
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        // A partial update may have left a clip behind.
        if (partialUpdatesAllowed) {
            dc.clearClip();
        }

        Clock.read();

        if (isAlwaysOn()) {
            drawAlwaysOn(dc);
            return;
        }

        refreshReadings();
        smooth(dc);
        paintBackground(dc);

        rimMarks.draw(dc);
        numerals.draw(dc, activityTimer.isRunning());
        windBearing.draw(dc);
        statusBar.draw(dc);
        timeDisplay.draw(dc);
        sunField.draw(dc);
        drawEditable(dc);
        hourHand.draw(dc);
        drawSecondsHand(dc);
    }

    //! Once a second in low power mode; has to stay within the power budget
    function onPartialUpdate(dc as Dc) as Void {
        if (!handIsVisible()) {
            return;
        }

        Clock.read();
        smooth(dc);
        secondsHand.drawPartial(dc, restoreRimCallback);
    }

    //! Put the rim back under the hand's old position, already clipped
    function restoreRim(dc as Dc, second as Number) as Void {
        paintBackground(dc);

        numerals.redraw(dc, second);
        statusBar.redraw(dc);
        sunField.redraw(dc);
        windBearing.redraw(dc);
        goalHand.redraw(dc);
        hourHand.redraw(dc);
    }

    //! The drawable the editor is about to pulse
    function getComplication(complication as ComplicationRef) as ComplicationDrawableRef? {
        var slotId = complication.uniqueIdentifier;

        // Not on the face: nothing to pulse.
        if (slotId == SlotId.GOAL) {
            return goalHand.isEnabled() ? pulse(goalHand, goalHand.getBoundingBox()) : null;
        }

        var field = fieldAt(slotId);

        if (field == null) {
            return null;
        }

        return pulse(field, field.getBoundingBox());
    }

    //! The slot under a tap, or null
    function getTappedComplication(x as Number, y as Number) as Number? {
        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].containsPoint(x, y)) {
                return fields[i].getSlotId();
            }
        }

        return null;
    }

    function onComplicationChange(complicationId as Complications.Id) as Void {
        var field = fieldShowing(complicationId);

        if (field == null) {
            return;
        }

        field.refresh();
        WatchUi.requestUpdate();
    }

    //! The hand would freeze once the system stops calling onPartialUpdate,
    //! so it comes off the screen in low power mode instead
    function turnPartialUpdatesOff() as Void {
        partialUpdatesAllowed = false;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        isAwake = true;
        WatchUi.requestUpdate();
    }

    //! The marks size the rest of the rim
    private function prepareRim(dc as Dc) as Void {
        rimMarks.prepare();

        var markReach = rimMarks.reach();
        var markWidth = rimMarks.width();

        numerals.prepare(dc, markReach);
        secondsHand.prepare(markReach, markWidth);
        windBearing.prepare(secondsHand.baseWidth());
        hourHand.prepare(rimMarks.minorReach());
        goalHand.prepare(markReach, markWidth);
    }

    private function placeFields(dc as Dc) as Void {
        var frame = (Dial.screenHeight * FRAME_RATIO).toNumber();
        var top = frame + (Dial.screenHeight * FIELD_DROP_RATIO).toNumber();

        var fieldHeight = centerField.heightIn(dc);
        var sunTop = top + fieldHeight + (Dial.screenHeight * SUN_DROP_RATIO).toNumber();

        centerField.prepare(dc, Dial.centerX, top + (fieldHeight / 2));
        sunField.prepare(dc, Dial.centerX, sunTop);

        statusBar.mirror(frame);
    }

    //! Null without watch face configuration support: the defaults stand
    private function loadSettings() as Void {
        var settings = WatchFaceConfig.getSettings(null);

        if (settings != null) {
            updateConfiguration(settings, null);
        }
    }

    //! Everything the draw reads, before anything draws
    private function refreshReadings() as Void {
        daylight.refresh();
        sunField.refresh();
        windReading.refresh();
        activityTimer.refresh();
        refreshActivity();
        dayColors.refresh();
        rimMarks.setRecoveryHours(recovery.hoursLeft());
    }

    //! Shared by recovery and the goal hand
    private function refreshActivity() as Void {
        if (!activityShown) {
            return;
        }

        var info = activityReading.refresh();

        if (info == null) {
            return;
        }

        recovery.read(info);
        goalProgress.read(info);
    }

    //! Once per dc: the dc between two updates is the system's
    private function smooth(dc as Dc) as Void {
        if (canSmooth) {
            dc.setAntiAlias(true);
        }
    }

    private function paintBackground(dc as Dc) as Void {
        dc.setColor(BACKGROUND, BACKGROUND);
        dc.clear();
    }

    //! Everything but what the editor is pulsing
    private function drawEditable(dc as Dc) as Void {
        var pulsing = pulsed;

        if (pulsing != null) {
            pulsing.setVisible(false);
        }

        for (var i = 0; i < fields.size(); i++) {
            fields[i].draw(dc);
        }

        goalHand.draw(dc);

        // Put it back so the editor can still draw it.
        if (pulsing != null) {
            pulsing.setVisible(true);
        }
    }

    private function drawSecondsHand(dc as Dc) as Void {
        if (handIsVisible()) {
            secondsHand.draw(dc);
        } else {
            // Nothing on screen to lift off next tick.
            secondsHand.forget();
        }
    }

    private function isAlwaysOn() as Boolean {
        return needsBurnInProtection && !isAwake;
    }

    //! Only the time, within the burn-in rules; the rest comes back on waking
    private function drawAlwaysOn(dc as Dc) as Void {
        smooth(dc);
        paintBackground(dc);
        timeDisplay.draw(dc);
        secondsHand.forget();
    }

    //! In low power mode the hand shows only if it can keep moving, and
    //! never on a screen that needs burn-in protection
    private function handIsVisible() as Boolean {
        return isAwake || (partialUpdatesAllowed && !needsBurnInProtection);
    }

    private function pulse(drawable as WatchUi.Drawable, boundingBox as Graphics.BoundingBox) as ComplicationDrawableRef {
        pulsed = drawable;
        WatchUi.requestUpdate();

        return new WatchUi.ComplicationDrawableRef({
            :drawable => drawable,
            :boundingBox => boundingBox
        });
    }

    private function subscribeToComplications() as Void {
        for (var i = 0; i < fields.size(); i++) {
            Complications.subscribeToUpdates(fields[i].getComplicationId());
        }

        Complications.registerComplicationChangeCallback(method(:onComplicationChange));
    }

    //! The container in a slot, or null if the slot is not ours
    private function fieldAt(slotId as Object?) as ComplicationField? {
        if (!(slotId instanceof Lang.Number)) {
            return null;
        }

        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].getSlotId() == slotId) {
                return fields[i];
            }
        }

        return null;
    }

    //! The container showing a complication, or null
    private function fieldShowing(complicationId as Complications.Id) as ComplicationField? {
        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].shows(complicationId)) {
                return fields[i];
            }
        }

        return null;
    }

    private function applyStyle(styleId as Number?) as Void {
        var style = (styleId != null) ? styleId : Styles.DEFAULT;

        var windBearingShown = Styles.hasWindBearing(style);

        activityShown = Styles.hasActivity(style);

        numerals.setEnabled(Styles.hasNumerals(style));
        sunField.setEnabled(Styles.hasSunField(style));
        windBearing.setEnabled(windBearingShown);
        statusBar.setWindShown(!windBearingShown);
        rimMarks.setRecoveryShown(activityShown);
        goalHand.setEnabled(activityShown);
    }

    //! The accent color: what is meant to stand apart from the rest
    private function applyAccentColor(accentColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(accentColor);

        secondsHand.setColor(color);
        hourHand.setColor(color);
        goalHand.setColor(color);
        windBearing.setColor(color);
    }

    //! The data color: everything else, and the rim until the sun is known
    private function applyDataColor(dataColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(dataColor);

        timeDisplay.setColor(color);
        sunField.setColor(color);
        dayColors.setFallbackColor(color);
        rimMarks.setRecoveryColor(color);
        statusBar.setColor(color);

        for (var i = 0; i < fields.size(); i++) {
            fields[i].setColor(color);
        }
    }

    //! An editor color, or the default
    private function colorOf(chosen as WatchFaceConfig.Color?) as Number {
        if ((chosen != null) && (chosen.color != null)) {
            return chosen.color as Number;
        }

        return DEFAULT_COLOR;
    }

    private function applyComplications(slots as Array<WatchFaceConfig.ComplicationRef>?) as Void {
        if (slots == null) {
            return;
        }

        for (var i = 0; i < slots.size(); i++) {
            applySlot(slots[i]);
        }
    }

    private function applySlot(slot as WatchFaceConfig.ComplicationRef) as Void {
        var complicationId = slot.complicationId;

        if (slot.uniqueIdentifier == SlotId.GOAL) {
            applyGoal(complicationId);
            return;
        }

        var field = fieldAt(slot.uniqueIdentifier);

        if (field == null) {
            return;
        }

        if (complicationId != null) {
            field.setComplicationId(complicationId);
        }

        field.refresh();
    }

    //! null until picked: steps stand
    private function applyGoal(complicationId as Complications.Id?) as Void {
        if (complicationId != null) {
            goalProgress.setType(complicationId.getType());
        }
    }
}
