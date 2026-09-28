import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! AM or PM, on a 12 hour watch only.
class Meridiem extends Icon {

    //! Indexes into images
    private const MORNING_IMAGE = 0;
    private const AFTERNOON_IMAGE = 1;

    private var images as Array<ResourceId> = [
        Rez.Drawables.Am,
        Rez.Drawables.Pm
    ];

    private var isMorning as Boolean = true;

    function initialize() {
        Icon.initialize(null);
    }

    //! The 24 hour case first, so such a watch never loads a bitmap. The
    //! half is settled here once a draw, not on every bitmap() call.
    function isReporting(settings as System.DeviceSettings) as Boolean {
        if (settings.is24Hour) {
            return false;
        }

        isMorning = Clock.isMorning(Clock.now().hour);

        return true;
    }

    protected function bitmap() as BitmapResource {
        return choose(images, isMorning ? MORNING_IMAGE : AFTERNOON_IMAGE);
    }
}
