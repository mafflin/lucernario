import Toybox.Lang;

//! Lets a caller through once a minute, for readings asked for every draw
//! that move no faster than the minute. Goes by the time the view read.
class MinuteGate {

    private const NO_MINUTE = -1;

    private var lastMinute as Number = NO_MINUTE;

    function initialize() {
    }

    //! true the first time it is asked in each minute
    function opens() as Boolean {
        var minute = Clock.now().min;

        if (minute == lastMinute) {
            return false;
        }

        lastMinute = minute;

        return true;
    }
}
