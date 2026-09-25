import Toybox.Lang;
import Toybox.System;

//! Clock units and the 12 hour rule, and the one place the time and the
//! device settings are read: once per update, since a partial update pays
//! for every ask, every second.
module Clock {

    const HOURS_PER_HALF_DAY = 12;
    const MINUTES_PER_HOUR = 60;
    const SECONDS_PER_MINUTE = 60;
    const SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;

    //! As of the last read(), null before the first
    var time as System.ClockTime? = null;
    var deviceSettings as System.DeviceSettings? = null;

    //! Once per update, before anything draws
    function read() as Void {
        time = System.getClockTime();
        deviceSettings = System.getDeviceSettings();
    }

    //! Reads if nothing has yet, for a caller outside an update
    function now() as System.ClockTime {
        if (time == null) {
            read();
        }

        return time as System.ClockTime;
    }

    function settings() as System.DeviceSettings {
        if (deviceSettings == null) {
            read();
        }

        return deviceSettings as System.DeviceSettings;
    }

    //! The hour as the wearer reads it, by the 12/24 hour setting
    function displayHour(hour as Number) as Number {
        if (settings().is24Hour) {
            return hour;
        }

        return twelveHour(hour);
    }

    //! Midnight and noon read as 12, not 0
    function twelveHour(hour as Number) as Number {
        var onFace = hour % HOURS_PER_HALF_DAY;

        return (onFace == 0) ? HOURS_PER_HALF_DAY : onFace;
    }

    function isMorning(hour as Number) as Boolean {
        return hour < HOURS_PER_HALF_DAY;
    }
}
