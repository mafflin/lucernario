import Toybox.Complications;
import Toybox.Lang;

//! Today's sunrise and sunset, off the complications - the same numbers the
//! data container shows. Read once a minute.
class Daylight {

    //! Minutes past midnight, null when the watch has no answer
    private var _sunrise as Number? = null;
    private var _sunset as Number? = null;

    private var _sunriseId as Complications.Id;
    private var _sunsetId as Complications.Id;
    private var _reading as MinuteGate;

    function initialize() {
        _sunriseId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE);
        _sunsetId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET);
        _reading = new MinuteGate();
    }

    function refresh() as Void {
        if (!_reading.opens()) {
            return;
        }

        _sunrise = minutesOf(_sunriseId);
        _sunset = minutesOf(_sunsetId);
    }

    function sunrise() as Number? {
        return _sunrise;
    }

    function sunset() as Number? {
        return _sunset;
    }

    //! The complication carries seconds past midnight
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
