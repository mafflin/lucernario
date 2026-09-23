import Toybox.Complications;
import Toybox.Lang;

//! When the sun rises and sets today, which moments of the day fall in
//! daylight, and the color that says so.
//!
//! Read off the sunrise and sunset complications, the same numbers the data
//! container shows, so the two can never disagree. The system works them out
//! from the watch's own position, with or without weather from the phone.
//! Refreshed once a minute at most, which is far more often than the answer
//! moves: the marks ask on every full update.
class Daylight {

    //! The colors of a moment in daylight and after dark
    private const _DAY_COLOR = Palette.AMBER;
    private const _NIGHT_COLOR = Palette.SKY;

    //! No reading yet, or none available: a watch that does not carry the
    //! complications, or has no position to work them out from
    private var _sunrise as Number? = null;
    private var _sunset as Number? = null;

    private var _sunriseId as Complications.Id;
    private var _sunsetId as Complications.Id;

    private var _reading as MinuteGate;

    //! Constructor
    function initialize() {
        _sunriseId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE);
        _sunsetId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET);
        _reading = new MinuteGate();
    }

    //! Read today's sunrise and sunset, if the minute has moved on
    function refresh() as Void {
        if (!_reading.opens()) {
            return;
        }

        _sunrise = minutesOf(_sunriseId);
        _sunset = minutesOf(_sunsetId);
    }

    //! The color of a moment of the day: by whether the sun is up then, or
    //! the given fallback while the sun is not known
    //! @param minutes Minutes past midnight
    //! @param unknown The color to use until the sun is known
    //! @return The color to draw in
    function colorAt(minutes as Number, unknown as Number) as Number {
        var day = isDayAt(minutes);

        if (day == null) {
            return unknown;
        }

        return day ? _DAY_COLOR : _NIGHT_COLOR;
    }

    //! Whether the given moment of the day falls in daylight
    //! @param minutes Minutes past midnight
    //! @return true by day, false by night, null when the sun is not known
    function isDayAt(minutes as Number) as Boolean? {
        var sunrise = _sunrise;
        var sunset = _sunset;

        if ((sunrise == null) || (sunset == null)) {
            return null;
        }

        // Sunset before sunrise on the local clock means the sun is up across
        // midnight, so the day is everything outside the gap between them.
        if (sunset < sunrise) {
            return !((minutes >= sunset) && (minutes < sunrise));
        }

        return (minutes >= sunrise) && (minutes < sunset);
    }

    //! A sun event as minutes past local midnight. The complication carries
    //! it as seconds past midnight.
    //! @param id The sunrise or sunset complication
    //! @return The minutes, or null when the system has no value
    private function minutesOf(id as Complications.Id) as Number? {
        // Some watches throw on a complication they do not carry.
        try {
            var value = Complications.getComplication(id).value;

            if (value == null) {
                return null;
            }

            return ComplicationFormat.seconds(value) / Clock.SECONDS_PER_MINUTE;
        } catch (exception) {
            return null;
        }
    }
}
