import Toybox.Application.WatchFaceConfig;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The watch face: owns the elements and applies the configuration.
class LucernarioView extends WatchUi.WatchFace {

    //! Shares of the screen height: the line the status row mirrors, and the
    //! data container's drop below it
    private const _FRAME_RATIO = 0.66;
    private const _FIELD_DROP_RATIO = 0.02;

    private var _style as Number = Styles.DEFAULT;
    private var _background as Number = Graphics.COLOR_BLACK;

    private var _time as TimeDisplay;
    private var _daylight as Daylight;
    private var _dayColors as DayColors;
    private var _rimMarks as RimMarks;
    private var _numerals as RimNumerals;
    private var _hand as SecondsHand;
    private var _hourHand as HourHand;
    private var _goalHand as GoalHand;
    private var _windReading as WindReading;
    private var _windBearing as WindBearing;
    private var _activityTimer as ActivityTimer;
    private var _recovery as Recovery;
    private var _goalProgress as GoalProgress;
    private var _statusBar as StatusBar;
    private var _centerField as ComplicationField;
    private var _fields as Array<ComplicationField>;

    //! Whether the native watch face editor started the face
    private var _editMode as Boolean;

    //! The container or hand the editor is pulsing, hidden on the face meanwhile
    private var _edited as WatchUi.Drawable?;

    private var _isAwake as Boolean = true;

    //! Whether the system lets the hand move every second in low power mode
    private var _partialUpdatesAllowed as Boolean;

    //! Asked once: a partial update should not look a symbol up every tick
    private var _canSmooth as Boolean = false;

    //! Made once: a partial update should not allocate a Method every tick
    private var _restoreRim as Method(dc as Dc, second as Number) as Void;

    function initialize(editMode as Boolean) {
        WatchFace.initialize();

        _editMode = editMode;

        _time = new TimeDisplay();
        _daylight = new Daylight();
        _dayColors = new DayColors(_daylight);
        _rimMarks = new RimMarks(_dayColors);
        _numerals = new RimNumerals(_dayColors);
        _hand = new SecondsHand();
        _hourHand = new HourHand();
        _windReading = new WindReading();
        _windBearing = new WindBearing(_windReading);
        _activityTimer = new ActivityTimer();
        _recovery = new Recovery();
        _goalProgress = new GoalProgress();
        _goalHand = new GoalHand(_goalProgress);
        _statusBar = new StatusBar(_windReading);

        _centerField = new ComplicationField(FieldLocation.CENTER, Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY);
        _fields = [_centerField];

        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _restoreRim = method(:restoreRim);
    }

    //! Size everything for this screen and load the editor's settings
    function onLayout(dc as Dc) as Void {
        _canSmooth = (dc has :setAntiAlias);

        Dial.setup(dc);

        // The marks size the rest of the rim.
        _rimMarks.prepare();

        var markReach = _rimMarks.reach();

        _numerals.prepare(dc, markReach);
        _hand.prepare(markReach, _rimMarks.width());
        _windBearing.prepare(_hand.baseWidth());
        _hourHand.prepare(markReach, _rimMarks.width());
        _goalHand.prepare(markReach, _rimMarks.width());

        placeFields(dc);

        // Null without watch face configuration support: the defaults stand.
        var settings = WatchFaceConfig.getSettings(null);
        if (settings != null) {
            updateConfiguration(settings, null);
        }

        // The editor shows a snapshot; live updates are not worth the power.
        if (!_editMode) {
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
            _edited = null;
        }

        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        // A partial update may have left a clip behind.
        if (_partialUpdatesAllowed) {
            dc.clearClip();
        }

        Clock.read();
        _daylight.refresh();
        _windReading.refresh();
        _activityTimer.refresh();
        _recovery.refresh();
        _goalProgress.refresh();
        _dayColors.refresh();
        _rimMarks.setRecoveryHours(_recovery.hoursLeft());
        smooth(dc);

        dc.setColor(_background, _background);
        dc.clear();

        _rimMarks.draw(dc);
        _numerals.draw(dc, _activityTimer.isRunning());
        _windBearing.draw(dc);
        _statusBar.draw(dc);
        _time.draw(dc);
        drawEditable(dc);
        _hourHand.draw(dc);

        if (handIsVisible()) {
            _hand.draw(dc);
        } else {
            // Nothing on screen to lift off next tick.
            _hand.forget();
        }
    }

    //! Once a second in low power mode; has to stay within the power budget
    function onPartialUpdate(dc as Dc) as Void {
        if (!handIsVisible()) {
            return;
        }

        Clock.read();
        smooth(dc);
        _hand.drawPartial(dc, _restoreRim);
    }

    //! Put the rim back under the hand's old position, already clipped
    function restoreRim(dc as Dc, second as Number) as Void {
        dc.setColor(_background, _background);
        dc.clear();

        _numerals.redraw(dc, second);
        _statusBar.redraw(dc);
        _windBearing.redraw(dc);
        _goalHand.redraw(dc);
        _hourHand.redraw(dc);
    }

    //! The drawable for the slot the editor is about to pulse
    function getComplication(complication as ComplicationRef) as ComplicationDrawableRef? {
        var location = complication.uniqueIdentifier;

        // Off the face on every other style: nothing to pulse.
        if (location == FieldLocation.GOAL) {
            return _goalHand.isEnabled() ? pulse(_goalHand, _goalHand.getBoundingBox()) : null;
        }

        var field = fieldAt(location);

        if (field == null) {
            return null;
        }

        return pulse(field, field.getBoundingBox());
    }

    //! The slot under a tap, or null
    function getTappedComplication(x as Number, y as Number) as Number? {
        for (var i = 0; i < _fields.size(); i++) {
            if (_fields[i].containsPoint(x, y)) {
                return _fields[i].getLocation();
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
        _partialUpdatesAllowed = false;
        WatchUi.requestUpdate();
    }

    function onEnterSleep() as Void {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isAwake = true;
        WatchUi.requestUpdate();
    }

    //! Once per dc: the dc between two updates is the system's
    private function smooth(dc as Dc) as Void {
        if (_canSmooth) {
            dc.setAntiAlias(true);
        }
    }

    private function placeFields(dc as Dc) as Void {
        var frame = (Dial.screenHeight * _FRAME_RATIO).toNumber();
        var top = frame + (Dial.screenHeight * _FIELD_DROP_RATIO).toNumber();

        _centerField.prepare(dc, Dial.centerX, top + (_centerField.heightIn(dc) / 2));

        _statusBar.mirror(frame);
    }

    private function pulse(drawable as WatchUi.Drawable, boundingBox as Graphics.BoundingBox) as ComplicationDrawableRef {
        _edited = drawable;
        WatchUi.requestUpdate();

        return new WatchUi.ComplicationDrawableRef({
            :drawable => drawable,
            :boundingBox => boundingBox
        });
    }

    //! Draw the containers and the goal hand, leaving out whichever the
    //! editor is pulsing
    private function drawEditable(dc as Dc) as Void {
        var edited = _edited;

        if (edited != null) {
            edited.setVisible(false);
        }

        for (var i = 0; i < _fields.size(); i++) {
            _fields[i].draw(dc);
        }

        _goalHand.draw(dc);

        // Put it back so the editor can still draw it.
        if (edited != null) {
            edited.setVisible(true);
        }
    }

    private function subscribeToComplications() as Void {
        for (var i = 0; i < _fields.size(); i++) {
            Complications.subscribeToUpdates(_fields[i].getComplicationId());
        }

        Complications.registerComplicationChangeCallback(method(:onComplicationChange));
    }

    //! The container in a slot, or null if the slot is not ours
    private function fieldAt(location as Object?) as ComplicationField? {
        if (!(location instanceof Lang.Number)) {
            return null;
        }

        for (var i = 0; i < _fields.size(); i++) {
            if (_fields[i].getLocation() == location) {
                return _fields[i];
            }
        }

        return null;
    }

    //! The container showing a complication, or null
    private function fieldShowing(complicationId as Complications.Id) as ComplicationField? {
        for (var i = 0; i < _fields.size(); i++) {
            if (_fields[i].shows(complicationId)) {
                return _fields[i];
            }
        }

        return null;
    }

    private function applyComplications(complicationSettings as Array<WatchFaceConfig.ComplicationRef>?) as Void {
        if (complicationSettings == null) {
            return;
        }

        for (var i = 0; i < complicationSettings.size(); i++) {
            var slot = complicationSettings[i];

            if (slot.uniqueIdentifier == FieldLocation.GOAL) {
                applyGoal(slot.complicationId);
                continue;
            }

            var field = fieldAt(slot.uniqueIdentifier);

            if (field == null) {
                continue;
            }

            var complicationId = slot.complicationId;
            if (complicationId != null) {
                field.setComplicationId(complicationId);
            }

            field.refresh();
        }
    }

    //! null until the user picks one: steps stand
    private function applyGoal(complicationId as Complications.Id?) as Void {
        if (complicationId != null) {
            _goalProgress.setType(complicationId.getType());
        }
    }

    //! In low power mode the hand shows only if it can keep moving
    private function handIsVisible() as Boolean {
        return _isAwake || _partialUpdatesAllowed;
    }

    private function applyStyle(styleId as Number?) as Void {
        var style = Styles.DEFAULT;

        if (styleId != null) {
            style = styleId;
        }

        _style = style;
        _background = Styles.backgroundOf(style);
        _dayColors.setLight(Styles.isLight(style));

        // Each element holds its own switch for the complicated style.
        var complicated = Styles.isComplicated(style);

        _windBearing.setEnabled(complicated);
        _statusBar.setWindShown(!complicated);
        _rimMarks.setRecoveryShown(complicated);
        _goalHand.setEnabled(Styles.isOvercomplicated(style));
    }

    //! The accent color: what is meant to stand apart from the rest
    private function applyAccentColor(accentColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(accentColor);

        _hand.setColor(color);
        _hourHand.setColor(color);
        _goalHand.setColor(color);
        _windBearing.setColor(color);
        _rimMarks.setRecoveryColor(color);
    }

    //! The data color: everything else, and the rim until the sun is known
    private function applyDataColor(dataColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(dataColor);

        _time.setColor(color);
        _dayColors.setColor(color);
        _statusBar.setColor(color);

        for (var i = 0; i < _fields.size(); i++) {
            _fields[i].setColor(color);
        }
    }

    //! An editor color, or whatever reads against the style's background
    private function colorOf(chosen as WatchFaceConfig.Color?) as Number {
        if ((chosen != null) && (chosen.color != null)) {
            return chosen.color as Number;
        }

        return Styles.foregroundOf(_style);
    }
}
