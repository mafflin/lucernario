import Toybox.Lang;
import Toybox.System;

//! Shown while a phone is connected.
class Phone extends Icon {

    function initialize() {
        Icon.initialize(Rez.Drawables.Phone);
    }

    function on(settings as System.DeviceSettings) as Boolean {
        return settings.phoneConnected;
    }
}
