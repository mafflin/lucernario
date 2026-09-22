import Toybox.Lang;
import Toybox.System;

//! Shown while the watch is connected to a phone.
class Phone extends Icon {

    //! Constructor
    function initialize() {
        Icon.initialize(Rez.Drawables.Phone);
    }

    //! @param settings The device settings
    //! @return true when a phone is connected
    function on(settings as System.DeviceSettings) as Boolean {
        return settings.phoneConnected;
    }
}
