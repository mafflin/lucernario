import Toybox.Lang;

//! Lets a caller through once a minute.
//!
//! For readings that are asked for every draw - and from the partial update,
//! every second - but move no faster than the minute hand: the battery level,
//! the weather. The caller does the work only when the gate opens. Goes by
//! the time the view read at the top of the update rather than asking again.
class MinuteGate {

    //! No minute has passed through yet
    private const _NO_MINUTE = -1;

    //! The minute the gate last opened on
    private var _minute as Number = _NO_MINUTE;

    //! Constructor
    function initialize() {
    }

    //! Whether the minute has moved on since the gate last opened
    //! @return true the first time this is asked in each minute
    function opens() as Boolean {
        var minute = Clock.now().min;

        if (minute == _minute) {
            return false;
        }

        _minute = minute;

        return true;
    }
}
