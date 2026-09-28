import Toybox.Lang;
import Toybox.System;

//! Shown while an alarm is set.
class Alarm extends Icon {

    function initialize() {
        Icon.initialize(Rez.Drawables.Alarm);
    }

    function isReporting(settings as System.DeviceSettings) as Boolean {
        var count = settings.alarmCount;

        return (count != null) && (count > 0);
    }
}
