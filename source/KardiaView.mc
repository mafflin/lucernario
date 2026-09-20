import Toybox.Application.WatchFaceConfig;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The watch face itself. Owns the elements drawn on it and the configuration
//! that styles them.
class KardiaView extends WatchUi.WatchFace {

    //! Color of the time and the hour marks when the editor has not set one
    private const _DEFAULT_ACCENT_COLOR = Graphics.COLOR_WHITE;

    //! Color of the seconds hand when the editor has not set one
    private const _DEFAULT_DATA_COLOR = Graphics.COLOR_WHITE;

    //! Style used when the editor has not set one
    private const _DEFAULT_STYLE = Styles.TIME_ONLY;

    //! The time in the center of the screen
    private var _time as TimeDisplay;

    //! The hour marks around the rim
    private var _rimMarks as RimMarks;

    //! The seconds hand sweeping the rim
    private var _hand as SecondsHand;

    //! Whether the selected style shows the rim: the marks and the hand
    private var _showRim as Boolean = false;

    //! Whether the watch face is in high power mode
    private var _isAwake as Boolean = true;

    //! Whether the system will let us move the hand once per second while in
    //! low power mode. Turned off if we exceed the power budget.
    private var _partialUpdatesAllowed as Boolean;

    //! Whether the time still has to be sized to the space left for it
    private var _timeNeedsLayout as Boolean = true;

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

        // Null on devices without watch face configuration support, in which
        // case the defaults stand.
        var settings = WatchFaceConfig.getSettings(null);
        if (settings != null) {
            updateConfiguration(settings, null);
        }

        layOutTime(dc);
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

        if (_timeNeedsLayout) {
            layOutTime(dc);
        }

        HandDrawer.smooth(dc);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (_showRim) {
            _rimMarks.draw(dc);
        }

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
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
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

    //! Size the time to whatever the rim leaves it
    //! @param dc The drawing context
    private function layOutTime(dc as Dc) as Void {
        _time.prepare(dc, _showRim ? Dial.ringDepth : 0);
        _timeNeedsLayout = false;
    }

    //! Whether the hand should be on screen right now. In low power mode that
    //! depends on being able to keep it moving.
    //! @return true when the hand should be drawn
    private function handIsVisible() as Boolean {
        if (!_showRim) {
            return false;
        }

        return _isAwake || _partialUpdatesAllowed;
    }

    //! Turn the selected style into the elements it shows
    //! @param styleId The style chosen in the editor, null if unset
    private function applyStyle(styleId as Number?) as Void {
        var style = _DEFAULT_STYLE;

        if (styleId != null) {
            style = styleId;
        }

        var showRim = (style == Styles.TIME_WITH_SECONDS);

        // The rim takes its space out of the time, so the time has to be
        // sized again whenever it comes or goes.
        if (showRim != _showRim) {
            _showRim = showRim;
            _timeNeedsLayout = true;
        }
    }

    //! Apply the chosen accent color to the time and the hour marks
    //! @param accentColor The color chosen in the editor, null if unset
    private function applyAccentColor(accentColor as WatchFaceConfig.Color?) as Void {
        var color = colorOf(accentColor, _DEFAULT_ACCENT_COLOR);

        _time.setColor(color);
        _rimMarks.setColor(color);
    }

    //! Apply the chosen data color to the seconds hand, so it can be set
    //! apart from the marks it sweeps over
    //! @param dataColor The color chosen in the editor, null if unset
    private function applyDataColor(dataColor as WatchFaceConfig.Color?) as Void {
        _hand.setColor(colorOf(dataColor, _DEFAULT_DATA_COLOR));
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
