import Toybox.Complications;
import Toybox.Lang;

//! When the sun rises and sets today, and which hours of the day fall in
//! daylight.
//!
//! Read off the sunrise and sunset complications, the same numbers the data
//! container shows, so the two can never disagree. The system works them out
//! from the watch's own position, with or without weather from the phone.
//! Refreshed once a minute at most, which is far more often than the answer
//! moves: the marks ask on every full update.
class Daylight {

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

    //! When the sun rises today
    //! @return Minutes past local midnight, or null when not known
    function sunrise() as Number? {
        return _sunrise;
    }

    //! When the sun sets today
    //! @return Minutes past local midnight, or null when not known
    function sunset() as Number? {
        return _sunset;
    }

    //! Whether the given hour of the day, on the hour, falls in daylight
    //! @param hour The hour of the day, 0 to 23
    //! @return true by day, false by night, null when the sun is not known
    function isDay(hour as Number) as Boolean? {
        var sunrise = _sunrise;
        var sunset = _sunset;

        if ((sunrise == null) || (sunset == null)) {
            return null;
        }

        var minutes = hour * Clock.MINUTES_PER_HOUR;

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
