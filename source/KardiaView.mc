import Toybox.Application.WatchFaceConfig;
import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The watch face itself. Owns the elements drawn on it and the configuration
//! that styles them.
class KardiaView extends WatchUi.WatchFace {

    //! The background the face is drawn on, which the style chooses
    private var _background as Number = Graphics.COLOR_BLACK;

    //! Style used when the editor has not set one
    private const _DEFAULT_STYLE = Styles.DARK;

    //! The time in the center of the screen
    private var _time as TimeDisplay;

    //! The hour marks around the rim
    private var _rimMarks as RimMarks;

    //! The seconds hand sweeping the rim
    private var _hand as SecondsHand;

    //! The row of status icons above the time
    private var _statusBar as StatusBar;

    //! The data container below the time, indexed by FieldLocation - 1
    private var _fields as Array<ComplicationField>;

    //! Whether the view was started by the native watch face editor
    private var _editMode as Boolean;

    //! The container the editor is currently letting the user pick, if any.
    //! It is hidden on the face while the editor pulses it in place.
    private var _editedField as ComplicationField?;

    //! Whether the selected style is dark on light rather than light on dark
    private var _isLight as Boolean = false;

    //! Whether the watch face is in high power mode
    private var _isAwake as Boolean = true;

    //! Whether the system will let us move the hand once per second while in
    //! low power mode. Turned off if we exceed the power budget.
    private var _partialUpdatesAllowed as Boolean;

    //! How far below the digits the data container sits, as a fraction of
    //! the screen height
    private const _FIELD_GAP_RATIO = 0.02;

    //! Constructor
    //! @param editMode Whether the native watch face editor started this view
    function initialize(editMode as Boolean) {
        WatchFace.initialize();

        _editMode = editMode;

        _time = new TimeDisplay();
        _rimMarks = new RimMarks();
        _hand = new SecondsHand();
        _statusBar = new StatusBar();

        _fields = [
            new ComplicationField(FieldLocation.CENTER, Complications.COMPLICATION_TYPE_STEPS)
        ];
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
    }

    //! Size the elements for this device and load the configuration set in
    //! the native watch face editor
    //! @param dc The drawing context
    function onLayout(dc as Dc) as Void {
        Dial.setup(dc);
        ClipRegion.setup();
        HandDrawer.setup(dc);

        _rimMarks.prepare();
        _hand.prepare();

        // The rim is always drawn, so the time is always fitted inside it.
        _time.prepare(dc, Dial.ringDepth);

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

        HandDrawer.smooth(dc);

        dc.setColor(_background, _background);
        dc.clear();

        _rimMarks.draw(dc);
        _statusBar.draw(dc);
        _time.draw(dc);
        drawFields(dc);

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

        HandDrawer.smooth(dc);
        _hand.drawPartial(dc, self);
    }

    //! Put the rim back where the hand has just been. Called by the hand with
    //! the old position already clipped, so this only touches those pixels.
    //! @param dc The drawing context
    function restoreRim(dc as Dc) as Void {
        dc.setColor(_background, _background);
        dc.clear();

        _rimMarks.redraw(dc);
        _statusBar.redraw(dc);
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

    //! Put the container on the centerline below the digits
    //! @param dc The drawing context
    private function placeFields(dc as Dc) as Void {
        var gap = (dc.getHeight() * _FIELD_GAP_RATIO).toNumber();

        // Sit it just under the time rather than at a fixed height: the time
        // is sized to the device, so where it ends moves with it.
        var rowCenterY = _time.inkBottomIn(dc) + gap + (_fields[0].heightIn(dc) / 2);

        _fields[FieldLocation.CENTER - 1].prepare(dc, dc.getWidth() / 2, rowCenterY);
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

    //! Ask the system to tell us when either complication changes
    private function subscribeToComplications() as Void {
        for (var i = 0; i < _fields.size(); i++) {
            Complications.subscribeToUpdates(_fields[i].getComplicationId());
        }

        Complications.registerComplicationChangeCallback(method(:onComplicationChange));
    }

    //! The container in the given slot
    //! @param location The slot, from FieldLocation
    //! @return The container, or null if the slot is not one of ours
    private function fieldAt(location as Object?) as ComplicationField? {
        if (!(location instanceof Lang.Number)) {
            return null;
        }

        var index = location - 1;

        if ((index < 0) || (index >= _fields.size())) {
            return null;
        }

        return _fields[index];
    }

    //! The container currently showing the given complication
    //! @param complicationId The complication to look for
    //! @return The container, or null if neither shows it
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

    //! Turn the selected style into the way round the colors go
    //! @param styleId The style chosen in the editor, null if unset
    private function applyStyle(styleId as Number?) as Void {
        var style = _DEFAULT_STYLE;

        if (styleId != null) {
            style = styleId;
        }

        _isLight = Styles.isLight(style);
        _background = _isLight ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }

    //! Apply the chosen accent color to the seconds hand, the one thing on
    //! the face that is meant to stand apart from the rest
    //! @param accentColor The color chosen in the editor, null if unset
    private function applyAccentColor(accentColor as WatchFaceConfig.Color?) as Void {
        _hand.setColor(colorOf(accentColor, defaultForeground()));
    }

    //! Apply the chosen data color to everything the hand sweeps over: the
    //! time, the hour marks, the status icons and the data containers
    //! @param dataColor The color chosen in the editor, null if unset
    private function applyDataColor(dataColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(dataColor, defaultForeground());

        _time.setColor(color);
        _rimMarks.setColor(color);
        _statusBar.setColor(color);

        for (var i = 0; i < _fields.size(); i++) {
            _fields[i].setColor(color);
        }
    }

    //! The color to draw with when the editor has not chosen one: whatever
    //! reads against the background this style picked
    //! @return The default foreground color
    private function defaultForeground() as Number {
        return _isLight ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }

    //! Unwrap a color from the editor, falling back when it has not set one
    //! @param chosen The color from the configuration
    //! @param fallback The color to use when nothing is set
    //! @return The color to draw with
    private function colorOf(chosen as WatchFaceConfig.Color?, fallback as Number) as Number {
        if ((chosen != null) && (chosen.color != null)) {
            return chosen.color as Number;
        }

        return fallback;
    }
}
