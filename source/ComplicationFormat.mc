import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;

//! Turns a complication's raw value into something a person can read.
//!
//! The system hands over a number and, sometimes, a unit; it never formats
//! anything. Most types are a plain count that the unit finishes off, but a
//! few carry a time in seconds, which is meaningless on its own: sunset comes
//! back as 69238 rather than 19:13.
module ComplicationFormat {

    const SECONDS_PER_MINUTE = 60;
    const SECONDS_PER_HOUR = 3600;

    //! Hours on a 12 hour clock face
    const HOURS_PER_HALF_DAY = 12;

    //! What to show when there is nothing to show
    const NOTHING = "";

    //! The complication's value, formatted for its type
    //! @param complication The complication to read
    //! @return The text to draw
    function text(complication as Complications.Complication) as String {
        var value = complication.value;

        if (value == null) {
            return NOTHING;
        }

        var type = complication.getType();

        if (isTimeOfDay(type)) {
            return clockTime(seconds(value));
        }

        if (isDuration(type)) {
            return duration(seconds(value));
        }

        return withUnit(value, complication.unit);
    }

    //! Types whose value is a time of day, in seconds since midnight
    //! @param type The complication type, null if the system did not say
    //! @return true when the value is a time of day
    function isTimeOfDay(type as Complications.Type?) as Boolean {
        return (type == Complications.COMPLICATION_TYPE_SUNRISE)
            || (type == Complications.COMPLICATION_TYPE_SUNSET);
    }

    //! Types whose value is a length of time, in seconds
    //! @param type The complication type, null if the system did not say
    //! @return true when the value is a duration
    function isDuration(type as Complications.Type?) as Boolean {
        return (type == Complications.COMPLICATION_TYPE_RECOVERY_TIME)
            || (type == Complications.COMPLICATION_TYPE_RACE_PREDICTOR_5K)
            || (type == Complications.COMPLICATION_TYPE_RACE_PREDICTOR_10K)
            || (type == Complications.COMPLICATION_TYPE_RACE_PREDICTOR_HALF_MARATHON)
            || (type == Complications.COMPLICATION_TYPE_RACE_PREDICTOR_MARATHON);
    }

    //! A time of day as the watch would write it, honoring the 12/24 hour
    //! setting
    //! @param secondsOfDay Seconds since midnight
    //! @return The time as H:MM
    function clockTime(secondsOfDay as Number) as String {
        var hour = secondsOfDay / SECONDS_PER_HOUR;
        var minute = (secondsOfDay % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE;

        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % HOURS_PER_HALF_DAY;

            if (hour == 0) {
                hour = HOURS_PER_HALF_DAY;
            }
        }

        return Lang.format("$1$:$2$", [hour.format("%d"), minute.format("%02d")]);
    }

    //! A length of time, in whichever units read best at this size: hours and
    //! minutes once it runs past an hour, minutes and seconds below that
    //! @param total The duration in seconds
    //! @return The duration as H:MM or M:SS
    function duration(total as Number) as String {
        if (total >= SECONDS_PER_HOUR) {
            var hours = total / SECONDS_PER_HOUR;
            var minutes = (total % SECONDS_PER_HOUR) / SECONDS_PER_MINUTE;

            return Lang.format("$1$h$2$", [hours.format("%d"), minutes.format("%02d")]);
        }

        var wholeMinutes = total / SECONDS_PER_MINUTE;
        var remainder = total % SECONDS_PER_MINUTE;

        return Lang.format("$1$:$2$", [wholeMinutes.format("%d"), remainder.format("%02d")]);
    }

    //! The value as it stands, with whatever unit the system supplied. Most
    //! types need nothing more than this.
    //! @param value The complication value
    //! @param unit The unit, which is only sometimes a string
    //! @return The text to draw
    function withUnit(value as Complications.Value, unit as Complications.Unit or String or Null) as String {
        var text = number(value);

        if (!(unit instanceof Lang.String)) {
            return text;
        }

        if (unit.length() == 0) {
            return text;
        }

        return Lang.format("$1$$2$", [text, unit]);
    }

    //! A value as text, without losing a float to its decimals
    //! @param value The complication value
    //! @return The value as text
    function number(value as Complications.Value) as String {
        if (value instanceof Lang.Float) {
            return value.format("%.1f");
        }

        if (value instanceof Lang.Double) {
            return value.format("%.1f");
        }

        return Lang.format("$1$", [value]);
    }

    //! A value as whole seconds, whatever number type it arrived as
    //! @param value The complication value
    //! @return The value in seconds
    function seconds(value as Complications.Value) as Number {
        if (value instanceof Lang.Number) {
            return value;
        }

        if (value instanceof Lang.Float) {
            return value.toNumber();
        }

        if (value instanceof Lang.Double) {
            return value.toNumber();
        }

        return 0;
    }
}
