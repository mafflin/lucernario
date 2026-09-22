import Toybox.Lang;
import Toybox.System;

//! Shown while at least one alarm is set.
class Alarm extends Icon {

    //! Constructor
    function initialize() {
        Icon.initialize(Rez.Drawables.Alarm);
    }

    //! @param settings The device settings
    //! @return true when an alarm is set
    function on(settings as System.DeviceSettings) as Boolean {
        var count = settings.alarmCount;

        return (count != null) && (count > 0);
    }
}
