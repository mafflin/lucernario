import Toybox.Lang;

//! Lets a caller through once a minute, for readings asked for every draw
//! that move no faster than the minute. Goes by the time the view read.
class MinuteGate {

    private const _NO_MINUTE = -1;

    private var _minute as Number = _NO_MINUTE;

    function initialize() {
    }

    //! true the first time it is asked in each minute
    function opens() as Boolean {
        var minute = Clock.now().min;

        if (minute == _minute) {
            return false;
        }

        _minute = minute;

        return true;
    }
}
