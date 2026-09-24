import Toybox.Application.WatchFaceConfig;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The watch face itself. Owns the elements drawn on it and the configuration
//! that styles them.
class LucernarioView extends WatchUi.WatchFace {

    //! Where the top of the data container sits, as a fraction of the screen
    //! height
    private const _FIELD_TOP_RATIO = 0.66;

    //! The style chosen in the editor, which decides the background and the
    //! color everything falls back to
    private var _style as Number = Styles.DEFAULT;

    //! The background the face is drawn on, which the style chooses
    private var _background as Number = Graphics.COLOR_BLACK;

    //! The time in the center of the screen
    private var _time as TimeDisplay;

    //! Where the sun is through the day, which colors the rim
    private var _daylight as Daylight;

    //! The colors of the day, shared by the marks and the numerals
    private var _dayColors as DayColors;

    //! The hour and minor marks around the rim
    private var _rimMarks as RimMarks;

    //! The numerals every four hours, against the ends of their marks
    private var _numerals as RimNumerals;

    //! The seconds hand, an arrow inside the marks
    private var _hand as SecondsHand;

    //! The hour hand, a broad mark reaching past the hour marks
    private var _hourHand as HourHand;

    //! The wind, shared by the status row and the bearing on the dial
    private var _windReading as WindReading;

    //! The wind as a bearing on the dial, on the style that asks for it
    private var _windBearing as WindBearing;

    //! The row of status icons above the time
    private var _statusBar as StatusBar;

    //! The data container below the time
    private var _centerField as ComplicationField;

    //! Every data container on the face
    private var _fields as Array<ComplicationField>;

    //! Whether the view was started by the native watch face editor
    private var _editMode as Boolean;

    //! The container the editor is currently letting the user pick, if any.
    //! It is hidden on the face while the editor pulses it in place.
    private var _editedField as ComplicationField?;

    //! Whether the watch face is in high power mode
    private var _isAwake as Boolean = true;

    //! Whether the system will let us move the hand once per second while in
    //! low power mode. Turned off if we exceed the power budget.
    private var _partialUpdatesAllowed as Boolean;

    //! Whether the screen can smooth what it draws. Asked once: a partial
    //! update has no business looking a symbol up every tick.
    private var _canSmooth as Boolean = false;

    //! What the hand calls to put the rim back under its old position. Made
    //! once: a partial update has no business allocating a Method every tick.
    private var _restoreRim as Method(dc as Dc, second as Number) as Void;

    //! Constructor
    //! @param editMode Whether the native watch face editor started this view
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
        _statusBar = new StatusBar(_windReading);

        _centerField = new ComplicationField(FieldLocation.CENTER, Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY);
        _fields = [_centerField];

        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
        _restoreRim = method(:restoreRim);
    }

    //! Size the elements for this device and load the configuration set in
    //! the native watch face editor
    //! @param dc The drawing context
    function onLayout(dc as Dc) as Void {
        _canSmooth = (dc has :setAntiAlias);

        Dial.setup(dc);

        // The marks size the rest of the rim: the numerals and the seconds
        // hand sit inside their reach, and the hour hand is measured in
        // marks.
        _rimMarks.prepare();

        var markReach = _rimMarks.reach();

        _numerals.prepare(dc, markReach);
        _hand.prepare(markReach, _rimMarks.width());
        _windBearing.prepare(_hand.baseWidth());
        _hourHand.prepare(_rimMarks.width(), markReach);

        placeFields(dc);

        // Null on devices without watch face configuration support, in which
        // case the defaults stand.
        var settings = WatchFaceConfig.getSettings(null);
        if (settings != null) {
            updateConfiguration(settings, null);
        }

        // The editor shows a snapshot, so live updates are only worth the
        // power while the face is actually being worn.
        if (!_editMode) {
            subscribeToComplications();
        }
    }

    //! Apply the settings coming from the native watch face editor
    //! @param config The settings to apply
    //! @param editedType The configuration that changed, null while initializing
    function updateConfiguration(config as WatchFaceConfig.Settings, editedType as WatchFaceConfigType?) as Void {
        applyStyle(config.styleId);
        applyAccentColor(config.accentColor);
        applyDataColor(config.complicationColor);
        applyComplications(config.complicationSettings);

        // Once the user moves on to another setting, the container being
        // picked is no longer pulsing and can be drawn normally again.
        if (editedType != WatchUi.WATCH_FACE_CONFIG_TYPE_COMPLICATION) {
            _editedField = null;
        }

        WatchUi.requestUpdate();
    }

    //! Draw the whole watch face
    //! @param dc The drawing context
    function onUpdate(dc as Dc) as Void {
        // A previous partial update may have left a clipping region behind.
        if (_partialUpdatesAllowed) {
            dc.clearClip();
        }

        Clock.read();
        _daylight.refresh();
        _windReading.refresh();
        _dayColors.refresh();
        smooth(dc);

        dc.setColor(_background, _background);
        dc.clear();

        _rimMarks.draw(dc);
        _numerals.draw(dc, ActivityTimer.isRunning());
        _windBearing.draw(dc);
        _statusBar.draw(dc);
        _time.draw(dc);
        drawFields(dc);
        _hourHand.draw(dc);

        if (handIsVisible()) {
            _hand.draw(dc);
        } else {
            // Nothing of the hand is on screen to lift off next tick.
            _hand.forget();
        }
    }

    //! Move the hand on by a second. Called once per second while in low power
    //! mode, so it has to stay within the system's power budget.
    //! @param dc The drawing context
    function onPartialUpdate(dc as Dc) as Void {
        if (!handIsVisible()) {
            return;
        }

        Clock.read();
        smooth(dc);
        _hand.drawPartial(dc, _restoreRim);
    }

    //! Put the rim back where the hand has just been. Called by the hand with
    //! the old position already clipped, so this only touches those pixels.
    //! @param dc The drawing context
    //! @param second Where the hand has just been
    function restoreRim(dc as Dc, second as Number) as Void {
        dc.setColor(_background, _background);
        dc.clear();

        _numerals.redraw(dc, second);
        _statusBar.redraw(dc);
        _windBearing.redraw(dc);
        _hourHand.redraw(dc);
    }

    //! Hand the editor the drawable for the container it is about to let the
    //! user pick, so it can pulse it in place
    //! @param complication The slot the editor is working on
    //! @return A reference to that container's drawable
    function getComplication(complication as ComplicationRef) as ComplicationDrawableRef? {
        var field = fieldAt(complication.uniqueIdentifier);

        if (field == null) {
            return null;
        }

        _editedField = field;
        WatchUi.requestUpdate();

        return new WatchUi.ComplicationDrawableRef({
            :drawable => field,
            :boundingBox => field.getBoundingBox()
        });
    }

    //! Which container, if any, sits under the given point
    //! @param x The x coordinate of the tap
    //! @param y The y coordinate of the tap
    //! @return The slot that was tapped, or null
    function getTappedComplication(x as Number, y as Number) as Number? {
        for (var i = 0; i < _fields.size(); i++) {
            if (_fields[i].containsPoint(x, y)) {
                return _fields[i].getLocation();
            }
        }

        return null;
    }

    //! Called by the system when a subscribed complication has new data
    //! @param complicationId The complication that changed
    function onComplicationChange(complicationId as Complications.Id) as Void {
        var field = fieldShowing(complicationId);

        if (field == null) {
            return;
        }

        field.refresh();
        WatchUi.requestUpdate();
    }

    //! Stop moving the hand every second.
    //!
    //! Called when onPartialUpdate costs more than the system allows. Once the
    //! system stops calling it the hand would freeze, so it is taken off the
    //! screen in low power mode instead of left standing still.
    function turnPartialUpdatesOff() as Void {
        _partialUpdatesAllowed = false;
        WatchUi.requestUpdate();
    }

    //! Called when the watch face enters low power mode
    function onEnterSleep() as Void {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

    //! Called when the watch face exits low power mode
    function onExitSleep() as Void {
        _isAwake = true;
        WatchUi.requestUpdate();
    }

    //! Turn smoothing on for everything drawn after it.
    //!
    //! Asserted once per dc the system hands the face rather than by each
    //! shape around itself, and re-asserted every update because the dc
    //! between two updates is the system's.
    //! @param dc The drawing context
    private function smooth(dc as Dc) as Void {
        if (_canSmooth) {
            dc.setAntiAlias(true);
        }
    }

    //! Put the container on the centerline below the time
    //! @param dc The drawing context
    private function placeFields(dc as Dc) as Void {
        var top = (dc.getHeight() * _FIELD_TOP_RATIO).toNumber();
        var rowCenterY = top + (_centerField.heightIn(dc) / 2);

        _centerField.prepare(dc, dc.getWidth() / 2, rowCenterY);

        // Frame the time: the status row sits as far above the middle as the
        // container sits below it.
        _statusBar.mirror(_centerField.locY.toNumber());
    }

    //! Draw the containers, leaving out the one the editor is pulsing
    //! @param dc The drawing context
    private function drawFields(dc as Dc) as Void {
        var edited = _editedField;

        if (edited != null) {
            edited.setVisible(false);
        }

        for (var i = 0; i < _fields.size(); i++) {
            _fields[i].draw(dc);
        }

        // Put it back so the editor can still draw it when it asks.
        if (edited != null) {
            edited.setVisible(true);
        }
    }

    //! Ask the system to tell us when a shown complication changes
    private function subscribeToComplications() as Void {
        for (var i = 0; i < _fields.size(); i++) {
            Complications.subscribeToUpdates(_fields[i].getComplicationId());
        }

        Complications.registerComplicationChangeCallback(method(:onComplicationChange));
    }

    //! The container in the given slot
    //! @param location The slot, from FieldLocation, as the editor hands it over
    //! @return The container, or null if the slot is not one of ours
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

    //! The container currently showing the given complication
    //! @param complicationId The complication to look for
    //! @return The container, or null if none shows it
    private function fieldShowing(complicationId as Complications.Id) as ComplicationField? {
        for (var i = 0; i < _fields.size(); i++) {
            if (_fields[i].shows(complicationId)) {
                return _fields[i];
            }
        }

        return null;
    }

    //! Assign the chosen complications to their slots
    //! @param complicationSettings The slots as the editor has them, null if unset
    private function applyComplications(complicationSettings as Array<WatchFaceConfig.ComplicationRef>?) as Void {
        if (complicationSettings == null) {
            return;
        }

        for (var i = 0; i < complicationSettings.size(); i++) {
            var slot = complicationSettings[i];
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

    //! Whether the hand should be on screen right now. In low power mode that
    //! depends on being able to keep it moving.
    //! @return true when the hand should be drawn
    private function handIsVisible() as Boolean {
        return _isAwake || _partialUpdatesAllowed;
    }

    //! Take the selected style, which decides which way round the colors go
    //! @param styleId The style chosen in the editor, null if unset
    private function applyStyle(styleId as Number?) as Void {
        var style = Styles.DEFAULT;

        if (styleId != null) {
            style = styleId;
        }

        _style = style;
        _background = Styles.backgroundOf(style);
        _dayColors.setLight(Styles.isLight(style));

        var windBearing = Styles.showsWindBearing(style);

        _windBearing.setEnabled(windBearing);
        _statusBar.setWindShown(!windBearing);
    }

    //! Apply the chosen accent color to the hands and the wind bearing, the
    //! things on the face that are meant to stand apart from the rest
    //! @param accentColor The color chosen in the editor, null if unset
    private function applyAccentColor(accentColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(accentColor);

        _hand.setColor(color);
        _hourHand.setColor(color);
        _windBearing.setColor(color);
    }

    //! Apply the chosen data color to everything the hand sweeps over: the
    //! time, the status icons and the data containers, and
    //! the rim marks and numerals until the sun is known
    //! @param dataColor The color chosen in the editor, null if unset
    private function applyDataColor(dataColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(dataColor);

        _time.setColor(color);
        _dayColors.setColor(color);
        _statusBar.setColor(color);

        for (var i = 0; i < _fields.size(); i++) {
            _fields[i].setColor(color);
        }
    }

    //! Unwrap a color from the editor, falling back to whatever reads against
    //! the style's background when it has not set one
    //! @param chosen The color from the configuration
    //! @return The color to draw with
    private function colorOf(chosen as WatchFaceConfig.Color?) as Number {
        if ((chosen != null) && (chosen.color != null)) {
            return chosen.color as Number;
        }

        return Styles.foregroundOf(_style);
    }
}
