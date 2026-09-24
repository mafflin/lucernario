import Toybox.Lang;
import Toybox.System;

//! The arithmetic of a clock: how long its units are, and how an hour reads
//! on a 12 hour watch.
//!
//! Shared by everything that shows a time - the digits, the meridiem, the
//! sunrise and sunset complications - so the 12 hour rule lives in one place.
//!
//! Also the one place the time and the device settings are read. The view
//! reads them once at the top of each update and everything drawn in that
//! update takes them from here: the hand, the battery gate and the digits
//! each asked the system on their own, and a partial update pays for every
//! ask, every second.
module Clock {

    const HOURS_PER_HALF_DAY = 12;
    const MINUTES_PER_HOUR = 60;
    const SECONDS_PER_MINUTE = 60;
    const SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR;

    //! The time and the device settings as of the last read(), null before
    //! the first
    var time as System.ClockTime? = null;
    var deviceSettings as System.DeviceSettings? = null;

    //! Read the time and the settings off the system. Once per update,
    //! before anything draws.
    function read() as Void {
        time = System.getClockTime();
        deviceSettings = System.getDeviceSettings();
    }

    //! The time as of the last read(). Reads it if nothing has yet, so a
    //! caller outside an update still gets an answer.
    //! @return The current time
    function now() as System.ClockTime {
        if (time == null) {
            read();
        }

        return time as System.ClockTime;
    }

    //! The device settings as of the last read(). Reads them if nothing has
    //! yet, so a caller outside an update still gets an answer.
    //! @return The device settings
    function settings() as System.DeviceSettings {
        if (deviceSettings == null) {
            read();
        }

        return deviceSettings as System.DeviceSettings;
    }

    //! The hour as the wearer expects to read it, honoring the device's 12/24
    //! hour setting
    //! @param hour The hour of the day, 0 to 23
    //! @return The hour to show
    function displayHour(hour as Number) as Number {
        if (settings().is24Hour) {
            return hour;
        }

        return twelveHour(hour);
    }

    //! The hour on a 12 hour clock face. Midnight and noon read as 12, not 0.
    //! @param hour The hour of the day, 0 to 23
    //! @return The hour, 1 to 12
    function twelveHour(hour as Number) as Number {
        var onFace = hour % HOURS_PER_HALF_DAY;

        return (onFace == 0) ? HOURS_PER_HALF_DAY : onFace;
    }

    //! Whether an hour falls in the first half of the day
    //! @param hour The hour of the day, 0 to 23
    //! @return true before noon
    function isMorning(hour as Number) as Boolean {
        return hour < HOURS_PER_HALF_DAY;
    }
}
