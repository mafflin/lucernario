import Toybox.Application.WatchFaceConfig;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The watch face itself. Owns the elements drawn on it and the configuration
//! that styles them.
class KardiaView extends WatchUi.WatchFace {

    //! Color of the time when the editor has not set one
    private const _DEFAULT_ACCENT_COLOR = Graphics.COLOR_WHITE;

    //! The time in the center of the screen
    private var _time as TimeDisplay;

    //! Constructor
    function initialize() {
        WatchFace.initialize();
        _time = new TimeDisplay();
    }

    //! Size the elements for this device and load the configuration set in
    //! the native watch face editor
    //! @param dc The drawing context
    function onLayout(dc as Dc) as Void {
        _time.prepare(dc);

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
        var accentColor = config.accentColor;

        if ((accentColor != null) && (accentColor.color != null)) {
            _time.setColor(accentColor.color as Number);
        } else {
            _time.setColor(_DEFAULT_ACCENT_COLOR);
        }

        WatchUi.requestUpdate();
    }

    //! Draw the watch face
    //! @param dc The drawing context
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        _time.draw(dc);
    }

    //! Called when the watch face enters low power mode
    function onEnterSleep() as Void {
        WatchUi.requestUpdate();
    }

    //! Called when the watch face exits low power mode
    function onExitSleep() as Void {
        WatchUi.requestUpdate();
    }
}
