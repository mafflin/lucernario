import Toybox.Complications;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! Turns a complication's raw value into readable text. The system hands
//! over a number and sometimes a unit, and almost never formats: times come
//! as seconds, temperature as Celsius, pressure as pascals, distances and
//! altitude as meters, percentages as bare numbers.
module ComplicationFormat {

    const CLOCK_FORMAT = "$1$:$2$";
    const HOURS_MINUTES_FORMAT = "$1$h$2$";

    //! The leading count as it is, the trailing one padded to two digits
    const LEADING_FORMAT = "%d";
    const TRAILING_FORMAT = "%02d";

    const DECIMAL_FORMAT = "%.1f";
    const VALUE_UNIT_FORMAT = "$1$$2$";

    const METERS_PER_KILOMETER = 1000.0;
    const METERS_PER_MILE = 1609.344;
    const KILOMETER = "km";
    const MILE = "mi";

    //! Whole kilometers would hide a short run
    const DISTANCE_FORMAT = "%.1f";

    const PERCENT = "%";

    const FEET_PER_METER = 3.28084;
    const METER = "m";
    const FOOT = "ft";

    const PASCALS_PER_BAR = 100000.0;

    //! A storm to a clear sky is about a twentieth of a bar
    const BAR_FORMAT = "%.3f";

    const FAHRENHEIT_PER_CELSIUS = 1.8;
    const FAHRENHEIT_AT_ZERO = 32.0;

    const NOTHING = "";
    const DEGREE = "°";

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

    //! Seconds since midnight
    function isTimeOfDay(type as Complications.Type?) as Boolean {
        return (type == Complications.COMPLICATION_TYPE_SUNRISE)
            || (type == Complications.COMPLICATION_TYPE_SUNSET);
    }

    //! Seconds
    function isDuration(type as Complications.Type?) as Boolean {
        return (type == Complications.COMPLICATION_TYPE_RECOVERY_TIME);
    }

    //! Meters whatever the watch shows; whole units, as fine as the
    //! altimeter knows
    function altitude(value as Complications.Value) as String {
        var height = decimal(value);

        if (Clock.settings().elevationUnits == System.UNIT_STATUTE) {
            return rounded(height * FEET_PER_METER) + FOOT;
        }

        return rounded(height) + METER;
    }

    //! A bare 0 to 100
    function isPercent(type as Complications.Type?) as Boolean {
        return (type == Complications.COMPLICATION_TYPE_BATTERY)
            || (type == Complications.COMPLICATION_TYPE_PULSE_OX)
            || (type == Complications.COMPLICATION_TYPE_SOLAR_INPUT);
    }

    //! Meters
    function isDistance(type as Complications.Type?) as Boolean {
        return (type == Complications.COMPLICATION_TYPE_WEEKLY_RUN_DISTANCE)
            || (type == Complications.COMPLICATION_TYPE_WEEKLY_BIKE_DISTANCE);
    }

    function percent(value as Complications.Value) as String {
        return whole(value) + PERCENT;
    }

    function distance(value as Complications.Value) as String {
        var meters = decimal(value);

        if (Clock.settings().distanceUnits == System.UNIT_STATUTE) {
            return (meters / METERS_PER_MILE).format(DISTANCE_FORMAT) + MILE;
        }

        return (meters / METERS_PER_KILOMETER).format(DISTANCE_FORMAT) + KILOMETER;
    }

    //! In bars; the BAR label carries the unit, and DeviceSettings has no
    //! pressure unit to follow
    function pressure(value as Complications.Value) as String {
        return (decimal(value) / PASCALS_PER_BAR).format(BAR_FORMAT);
    }

    //! Always Celsius, whatever the watch shows; whole degrees
    function temperature(value as Complications.Value) as String {
        var degrees = decimal(value);

        if (Clock.settings().temperatureUnits == System.UNIT_STATUTE) {
            degrees = (degrees * FAHRENHEIT_PER_CELSIUS) + FAHRENHEIT_AT_ZERO;
        }

        return rounded(degrees) + DEGREE;
    }

    //! The one type the system formats itself, as "H 21 / L 12" or similar,
    //! with no degree marks: one is put after each number
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

    //! Whether a degree mark belongs after this character
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

        // A separator with digits behind it is inside the number: 21.5 takes
        // one mark.
        return !(isSeparator(characters[next])
            && ((next + 1) < characters.size())
            && isDigit(characters[next + 1]));
    }

    function isDigit(character as Char) as Boolean {
        return (character >= '0') && (character <= '9');
    }

    function isSeparator(character as Char) as Boolean {
        return (character == '.') || (character == ',');
    }

    //! H:MM by the 12/24 hour setting
    function clockTime(secondsOfDay as Number) as String {
        var hour = Clock.displayHour(secondsOfDay / Clock.SECONDS_PER_HOUR);
        var minute = (secondsOfDay % Clock.SECONDS_PER_HOUR) / Clock.SECONDS_PER_MINUTE;

        return pair(CLOCK_FORMAT, hour, minute);
    }

    //! HhMM past an hour, M:SS below
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

    function pair(format as String, leading as Number, trailing as Number) as String {
        return Lang.format(format, [leading.format(LEADING_FORMAT), trailing.format(TRAILING_FORMAT)]);
    }

    //! The value with whatever unit the system supplied, if it is a string
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

    //! A float keeps a decimal
    function number(value as Complications.Value) as String {
        if ((value instanceof Lang.Float) || (value instanceof Lang.Double)) {
            return decimal(value).format(DECIMAL_FORMAT);
        }

        return value.toString();
    }

    function whole(value as Complications.Value) as String {
        return rounded(decimal(value));
    }

    function rounded(amount as Float) as String {
        return Math.round(amount).toNumber().format(LEADING_FORMAT);
    }

    //! Zero if not a number at all
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

    function seconds(value as Complications.Value) as Number {
        if (value instanceof Lang.Number) {
            return value;
        }

        return decimal(value).toNumber();
    }
}
