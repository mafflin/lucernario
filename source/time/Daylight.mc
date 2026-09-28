import Toybox.Complications;
import Toybox.Lang;

//! Today's sunrise and sunset, off the complications - the same numbers the
//! data container shows. Read once a minute.
class Daylight {

    //! Minutes past midnight, null when the watch has no answer
    private var sunriseMinute as Number? = null;
    private var sunsetMinute as Number? = null;

    private var sunriseId as Complications.Id;
    private var sunsetId as Complications.Id;
    private var minuteGate as MinuteGate;

    function initialize() {
        sunriseId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE);
        sunsetId = new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET);
        minuteGate = new MinuteGate();
    }

    function refresh() as Void {
        if (!minuteGate.opens()) {
            return;
        }

        sunriseMinute = minutesOf(sunriseId);
        sunsetMinute = minutesOf(sunsetId);
    }

    function sunrise() as Number? {
        return sunriseMinute;
    }

    function sunset() as Number? {
        return sunsetMinute;
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
