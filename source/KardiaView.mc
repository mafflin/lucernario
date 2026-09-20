import Toybox.Application.WatchFaceConfig;
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

    //! Whether the selected style is dark on light rather than light on dark
    private var _isLight as Boolean = false;

    //! Whether the watch face is in high power mode
    private var _isAwake as Boolean = true;

    //! Whether the system will let us move the hand once per second while in
    //! low power mode. Turned off if we exceed the power budget.
    private var _partialUpdatesAllowed as Boolean;

    //! Constructor
    function initialize() {
        WatchFace.initialize();

        _time = new TimeDisplay();
        _rimMarks = new RimMarks();
        _hand = new SecondsHand();
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

        // Null on devices without watch face configuration support, in which
        // case the defaults stand.
        var settings = WatchFaceConfig.getSettings(null);
        if (settings != null) {
            updateConfiguration(settings, null);
        }
    }

    //! Apply the settings coming from the native watch face editor
    //! @param config The settings to apply
    //! @param editedType The configuration that changed, null while initializing
    function updateConfiguration(config as WatchFaceConfig.Settings, editedType as WatchFaceConfigType?) as Void {
        applyStyle(config.styleId);
        applyAccentColor(config.accentColor);
        applyDataColor(config.complicationColor);

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
        _time.draw(dc);

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

    //! Apply the chosen accent color to the time and the hour marks
    //! @param accentColor The color chosen in the editor, null if unset
    private function applyAccentColor(accentColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(accentColor, defaultForeground());

        _time.setColor(color);
        _rimMarks.setColor(color);
    }

    //! Apply the chosen data color to the seconds hand, so it can be set
    //! apart from the marks it sweeps over
    //! @param dataColor The color chosen in the editor, null if unset
    private function applyDataColor(dataColor as WatchFaceConfig.Color?) as Void {
        _hand.setColor(colorOf(dataColor, defaultForeground()));
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
