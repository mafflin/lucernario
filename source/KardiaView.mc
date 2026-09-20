import Toybox.Application.WatchFaceConfig;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The watch face itself. Owns the elements drawn on it and the configuration
//! that styles them.
class KardiaView extends WatchUi.WatchFace {

    //! Color of the time when the editor has not set one
    private const _DEFAULT_ACCENT_COLOR = Graphics.COLOR_WHITE;

    //! Style used when the editor has not set one
    private const _DEFAULT_STYLE = Styles.TIME_ONLY;

    //! The time in the center of the screen
    private var _time as TimeDisplay;

    //! The seconds at the bottom of the screen
    private var _seconds as SecondsDisplay;

    //! Whether the selected style shows seconds
    private var _showSeconds as Boolean = false;

    //! Whether the watch face is in high power mode
    private var _isAwake as Boolean = true;

    //! Whether the system will let us redraw the seconds once per second while
    //! in low power mode. Turned off if we exceed the power budget.
    private var _partialUpdatesAllowed as Boolean;

    //! Whether the time reaches down into the seconds region. It normally
    //! does not, which lets partial updates skip redrawing it.
    private var _timeReachesSeconds as Boolean = false;

    //! Constructor
    function initialize() {
        WatchFace.initialize();

        _time = new TimeDisplay();
        _seconds = new SecondsDisplay();
        _partialUpdatesAllowed = (WatchUi.WatchFace has :onPartialUpdate);
    }

    //! Size the elements for this device and load the configuration set in
    //! the native watch face editor
    //! @param dc The drawing context
    function onLayout(dc as Dc) as Void {
        _time.prepare(dc);
        _seconds.prepare(dc);
        _timeReachesSeconds = (_time.bottomEdgeIn(dc) > _seconds.bounds()[1]);

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

        WatchUi.requestUpdate();
    }

    //! Draw the whole watch face
    //! @param dc The drawing context
    function onUpdate(dc as Dc) as Void {
        // A previous partial update may have left a clipping region behind.
        if (_partialUpdatesAllowed) {
            dc.clearClip();
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        _time.draw(dc);

        if (secondsAreVisible()) {
            _seconds.draw(dc);
        }
    }

    //! Redraw just the seconds. Called once per second while in low power
    //! mode, so it has to stay within the system's power budget.
    //! @param dc The drawing context
    function onPartialUpdate(dc as Dc) as Void {
        if (!secondsAreVisible()) {
            return;
        }

        var bounds = _seconds.bounds();
        dc.setClip(bounds[0], bounds[1], bounds[2], bounds[3]);

        // clear() honors the clip, so this repaints only the seconds region.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        // Clipping bounds the pixels written but not the cost of the call, so
        // the time is only redrawn on a device where it actually reaches in.
        if (_timeReachesSeconds) {
            _time.draw(dc);
        }

        _seconds.draw(dc);
    }

    //! Stop redrawing the seconds every second.
    //!
    //! Called when onPartialUpdate costs more than the system allows. Once the
    //! system stops calling it, seconds would freeze in low power mode, so
    //! they are hidden there instead of shown stale.
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

    //! Whether the seconds should be on screen right now. In low power mode
    //! that depends on being able to keep them ticking.
    //! @return true when the seconds should be drawn
    private function secondsAreVisible() as Boolean {
        if (!_showSeconds) {
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

        _showSeconds = (style == Styles.TIME_WITH_SECONDS);
    }

    //! Apply the chosen accent color to every element
    //! @param accentColor The color chosen in the editor, null if unset
    private function applyAccentColor(accentColor as WatchFaceConfig.Color?) as Void {
        var color = _DEFAULT_ACCENT_COLOR;

        if ((accentColor != null) && (accentColor.color != null)) {
            color = accentColor.color as Number;
        }

        _time.setColor(color);
        _seconds.setColor(color);
    }
}
