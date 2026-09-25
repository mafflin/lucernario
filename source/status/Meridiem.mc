import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! AM or PM, on a 12 hour watch only.
class Meridiem extends Icon {

    private const _MORNING = 0;
    private const _AFTERNOON = 1;

    private var _images as Array<ResourceId> = [
        Rez.Drawables.Am,
        Rez.Drawables.Pm
    ];

    private var _morning as Boolean = true;

    function initialize() {
        Icon.initialize(null);
    }

    //! The 24 hour case first, so such a watch never loads a bitmap. The
    //! half is settled here once a draw, not on every bitmap() call.
    function on(settings as System.DeviceSettings) as Boolean {
        if (settings.is24Hour) {
            return false;
        }

        _morning = Clock.isMorning(Clock.now().hour);

        return true;
    }

    protected function bitmap() as BitmapResource {
        return choose(_images, _morning ? _MORNING : _AFTERNOON);
    }
}
