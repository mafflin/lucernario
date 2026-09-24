import Toybox.Complications;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! Turns a complication's raw value into something a person can read.
//!
//! The system hands over a number and, sometimes, a unit; it almost never
//! formats anything. Most types are a plain count that the unit finishes off,
//! but a few carry a time in seconds, which is meaningless on its own: sunset
//! comes back as 69238 rather than 19:13.
//!
//! The temperatures need more than that. The current one is Celsius however
//! the watch is set, and the high and low is the one type the system formats
//! itself - a string with no degree mark on either number. The pressure comes
//! in pascals, which is six figures for a number read either side of one bar,
//! and the altitude in meters whatever the watch is set to. The weekly
//! distances are in meters as well, and the percentages arrive as a bare
//! number with nothing to say they are one.
module ComplicationFormat {

    //! How the two halves of a time or a duration sit together
    const CLOCK_FORMAT = "$1$:$2$";
    const HOURS_MINUTES_FORMAT = "$1$h$2$";

    //! A count of hours, minutes or seconds: the leading one as it is, the
    //! trailing one padded to two digits
    const LEADING_FORMAT = "%d";
    const TRAILING_FORMAT = "%02d";

    //! How finely a value that arrived with decimals keeps them
    const DECIMAL_FORMAT = "%.1f";

    //! A value followed straight by its unit
    const VALUE_UNIT_FORMAT = "$1$$2$";

    //! Meters to a kilometer and to a mile
    const METERS_PER_KILOMETER = 1000.0;
    const METERS_PER_MILE = 1609.344;

    //! The units a distance is shown in
    const KILOMETER = "km";
    const MILE = "mi";

    //! How finely a distance is shown. A week's running moves by more than a
    //! tenth of a unit, and whole kilometers would hide a short run.
    const DISTANCE_FORMAT = "%.1f";

    //! The unit a percentage is shown in
    const PERCENT = "%";

    //! Feet to a meter
    const FEET_PER_METER = 3.28084;

    //! The units an altitude is shown in
    const METER = "m";
    const FOOT = "ft";

    //! Pascals to a bar. The system reports pressure in pascals, which runs
    //! to six figures for a number that sits either side of one bar.
    const PASCALS_PER_BAR = 100000.0;

    //! How finely the pressure is shown. A bar is a coarse unit for weather -
    //! the swing from a storm to a clear sky is about a twentieth of one - so
    //! it takes three decimals to show any movement at all.
    const BAR_FORMAT = "%.3f";

    //! Degrees Fahrenheit to a degree Celsius
    const FAHRENHEIT_PER_CELSIUS = 1.8;

    //! Where the Fahrenheit scale has zero Celsius
    const FAHRENHEIT_AT_ZERO = 32.0;

    //! What to show when there is nothing to show
    const NOTHING = "";

    //! The degree mark. The high/low string arrives without one and there is
    //! no unit alongside it to supply it.
    const DEGREE = "°";

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

        if (type == Complications.COMPLICATION_TYPE_HIGH_LOW_TEMPERATURE) {
            return marked(value);
        }

        if (type == Complications.COMPLICATION_TYPE_CURRENT_TEMPERATURE) {
            return temperature(value);
        }

        if (type == Complications.COMPLICATION_TYPE_SEA_LEVEL_PRESSURE) {
            return pressure(value);
        }

        if (type == Complications.COMPLICATION_TYPE_ALTITUDE) {
            return altitude(value);
        }

        if (isPercent(type)) {
            return percent(value);
        }

        if (isDistance(type)) {
            return distance(value);
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
        return (type == Complications.COMPLICATION_TYPE_RECOVERY_TIME);
    }

    //! The altitude in the units the watch is set to.
    //!
    //! The value is meters whatever the watch displays, and arrives with the
    //! UNIT_ELEVATION enum rather than a string, so the unit has to be said
    //! here. Whole units: a tenth of a meter is more than the barometric
    //! altimeter knows.
    //! @param value The complication value, in meters
    //! @return The text to draw
    function altitude(value as Complications.Value) as String {
        var height = decimal(value);

        if (Clock.settings().elevationUnits == System.UNIT_STATUTE) {
            return rounded(height * FEET_PER_METER) + FOOT;
        }

        return rounded(height) + METER;
    }

    //! Types whose value is a percentage. The system reports these as a bare
    //! number between 0 and 100, with no unit to say so.
    //! @param type The complication type, null if the system did not say
    //! @return true when the value is a percentage
    function isPercent(type as Complications.Type?) as Boolean {
        return (type == Complications.COMPLICATION_TYPE_BATTERY)
            || (type == Complications.COMPLICATION_TYPE_PULSE_OX)
            || (type == Complications.COMPLICATION_TYPE_SOLAR_INPUT);
    }

    //! Types whose value is a distance, in meters
    //! @param type The complication type, null if the system did not say
    //! @return true when the value is a distance
    function isDistance(type as Complications.Type?) as Boolean {
        return (type == Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE)
            || (type == Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE);
    }

    //! A percentage, said as one
    //! @param value The complication value, between 0 and 100
    //! @return The text to draw
    function percent(value as Complications.Value) as String {
        return whole(value) + PERCENT;
    }

    //! A distance in the units the watch is set to.
    //!
    //! The value is meters, which is the wrong size for a week of it: a
    //! marathon comes back as 42195.0.
    //! @param value The complication value, in meters
    //! @return The text to draw
    function distance(value as Complications.Value) as String {
        var meters = decimal(value);

        if (Clock.settings().distanceUnits == System.UNIT_STATUTE) {
            return (meters / METERS_PER_MILE).format(DISTANCE_FORMAT) + MILE;
        }

        return (meters / METERS_PER_KILOMETER).format(DISTANCE_FORMAT) + KILOMETER;
    }

    //! The sea level pressure, in bars.
    //!
    //! The raw value is pascals - 101325 for a standard atmosphere - which is
    //! wider than the slot. The unit is not said here: it is the label, BAR,
    //! that carries it, and DeviceSettings has no pressure unit to follow in
    //! any case.
    //! @param value The complication value, in pascals
    //! @return The text to draw
    function pressure(value as Complications.Value) as String {
        return (decimal(value) / PASCALS_PER_BAR).format(BAR_FORMAT);
    }

    //! The current temperature in the units the watch is set to.
    //!
    //! The value is always Celsius, whatever the watch itself displays, and
    //! its unit is the UNIT_TEMPERATURE enum rather than a string, so nothing
    //! about the raw value says what it is. Whole degrees: a tenth of a degree
    //! is noise, and the slot is narrow.
    //! @param value The complication value, in degrees Celsius
    //! @return The text to draw
    function temperature(value as Complications.Value) as String {
        var degrees = decimal(value);

        if (Clock.settings().temperatureUnits == System.UNIT_STATUTE) {
            degrees = (degrees * FAHRENHEIT_PER_CELSIUS) + FAHRENHEIT_AT_ZERO;
        }

        return rounded(degrees) + DEGREE;
    }

    //! A high and a low with a degree mark after each of them.
    //!
    //! This type is the one the system formats itself: it hands over a string
    //! along the lines of "H 21 / L 12", with the numbers already in the
    //! user's units and no mark on either. The exact shape is documented only
    //! as "similar to", so the mark is placed by finding where each number
    //! ends rather than by taking the string apart.
    //! @param value The complication value
    //! @return The text to draw
    function marked(value as Complications.Value) as String {
        if (!(value instanceof Lang.String)) {
            // A watch that hands over one number instead of the pair.
            return whole(value) + DEGREE;
        }

        var characters = value.toCharArray();
        var text = NOTHING;

        for (var i = 0; i < characters.size(); i++) {
            text += characters[i].toString();

            if (endsNumber(characters, i)) {
                text += DEGREE;
            }
        }

        return text;
    }

    //! Whether the character at this position is the last digit of a number
    //! @param characters The whole string
    //! @param i Where to look
    //! @return true when a degree mark belongs after this character
    function endsNumber(characters as Array<Char>, i as Number) as Boolean {
        if (!isDigit(characters[i])) {
            return false;
        }

        var next = i + 1;

        if (next >= characters.size()) {
            return true;
        }

        if (isDigit(characters[next])) {
            return false;
        }

        // A separator with more digits behind it is inside the number, not
        // the end of it: 21.5 takes one mark, not two.
        return !(isSeparator(characters[next])
            && ((next + 1) < characters.size())
            && isDigit(characters[next + 1]));
    }

    //! Whether a character is a digit
    //! @param character The character to test
    //! @return true when it is 0 to 9
    function isDigit(character as Char) as Boolean {
        return (character >= '0') && (character <= '9');
    }

    //! Whether a character can sit between the digits of one number
    //! @param character The character to test
    //! @return true when it is a decimal point or comma
    function isSeparator(character as Char) as Boolean {
        return (character == '.') || (character == ',');
    }

    //! A time of day as the watch would write it, honoring the 12/24 hour
    //! setting
    //! @param secondsOfDay Seconds since midnight
    //! @return The time as H:MM
    function clockTime(secondsOfDay as Number) as String {
        var hour = Clock.displayHour(secondsOfDay / Clock.SECONDS_PER_HOUR);
        var minute = (secondsOfDay % Clock.SECONDS_PER_HOUR) / Clock.SECONDS_PER_MINUTE;

        return pair(CLOCK_FORMAT, hour, minute);
    }

    //! A length of time, in whichever units read best at this size: hours and
    //! minutes once it runs past an hour, minutes and seconds below that
    //! @param total The duration in seconds
    //! @return The duration as H:MM or M:SS
    function duration(total as Number) as String {
        if (total >= Clock.SECONDS_PER_HOUR) {
            var hours = total / Clock.SECONDS_PER_HOUR;
            var minutes = (total % Clock.SECONDS_PER_HOUR) / Clock.SECONDS_PER_MINUTE;

            return pair(HOURS_MINUTES_FORMAT, hours, minutes);
        }

        var minutes = total / Clock.SECONDS_PER_MINUTE;
        var seconds = total % Clock.SECONDS_PER_MINUTE;

        return pair(CLOCK_FORMAT, minutes, seconds);
    }

    //! Two counts laid out together, the trailing one padded to two digits
    //! @param format How the two sit together
    //! @param leading The larger unit
    //! @param trailing The smaller unit, 0 to 59
    //! @return The pair as text
    function pair(format as String, leading as Number, trailing as Number) as String {
        return Lang.format(format, [leading.format(LEADING_FORMAT), trailing.format(TRAILING_FORMAT)]);
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

        return Lang.format(VALUE_UNIT_FORMAT, [text, unit]);
    }

    //! A value as text, without losing a float to its decimals
    //! @param value The complication value
    //! @return The value as text
    function number(value as Complications.Value) as String {
        if ((value instanceof Lang.Float) || (value instanceof Lang.Double)) {
            return decimal(value).format(DECIMAL_FORMAT);
        }

        return value.toString();
    }

    //! A value rounded to a whole number, as text
    //! @param value The complication value
    //! @return The value as text, with no decimals
    function whole(value as Complications.Value) as String {
        return rounded(decimal(value));
    }

    //! A number rounded to a whole one, as text
    //! @param amount The number to round
    //! @return The number as text, with no decimals
    function rounded(amount as Float) as String {
        return Math.round(amount).toNumber().format(LEADING_FORMAT);
    }

    //! A value as a float, whatever number type it arrived as
    //! @param value The complication value
    //! @return The value as a float, or zero if it is not a number at all
    function decimal(value as Complications.Value) as Float {
        if (value instanceof Lang.Float) {
            return value;
        }

        if (value instanceof Lang.Double) {
            return value.toFloat();
        }

        if (value instanceof Lang.Number) {
            return value.toFloat();
        }

        return 0.0;
    }

    //! A value as whole seconds, whatever number type it arrived as
    //! @param value The complication value
    //! @return The value in seconds
    function seconds(value as Complications.Value) as Number {
        if (value instanceof Lang.Number) {
            return value;
        }

        return decimal(value).toNumber();
    }
}
