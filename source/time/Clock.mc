import Toybox.Lang;
import Toybox.System;

//! Clock units, minutes of the day and the 12 hour rule, and the one place
//! the time and the device settings are read: once per update.
module Clock {

    const HOURS_PER_HALF_DAY = 12;
    const HOURS_PER_DAY = 24;
    const MINUTES_PER_HOUR = 60;
    const MINUTES_PER_DAY = HOURS_PER_DAY * MINUTES_PER_HOUR;
    const SECONDS_PER_MINUTE = 60;

    //! As of the last read(), null before the first
    var time as System.ClockTime? = null;
    var deviceSettings as System.DeviceSettings? = null;

    //! Once per full update, before anything draws
    function read() as Void {
        readTime();
        deviceSettings = System.getDeviceSettings();
    }

    //! For a partial update, which needs nothing but the second
    function readTime() as Void {
        time = System.getClockTime();
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

    //! Minutes past midnight, as of the last read
    function minuteOfDay() as Number {
        var clockTime = now();

        return (clockTime.hour * MINUTES_PER_HOUR) + clockTime.min;
    }

    //! Into a day's minutes, from a day either side
    function wrapMinutes(minutes as Number) as Number {
        return (minutes + MINUTES_PER_DAY) % MINUTES_PER_DAY;
    }

    //! The hour as the wearer reads it, by the 12/24 hour setting
    function displayHour(hour as Number) as Number {
        if (settings().is24Hour) {
            return hour;
        }

        return twelveHour(hour);
    }

    function isMorning(hour as Number) as Boolean {
        return hour < HOURS_PER_HALF_DAY;
    }

    //! Midnight and noon read as 12, not 0
    function twelveHour(hour as Number) as Number {
        var onFace = hour % HOURS_PER_HALF_DAY;

        return (onFace == 0) ? HOURS_PER_HALF_DAY : onFace;
    }
}
