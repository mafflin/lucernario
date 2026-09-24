import Toybox.Activity;
import Toybox.Lang;

//! Whether an activity is under way: the system puts its own indicator at
//! the top of the screen while one is, over whatever the face drew there.
//!
//! Read off the activity timer, which a watch face may or may not be told
//! about depending on the device. Anything short of a clear answer counts as
//! no activity. The stopwatch is not an activity and does not show here.
//!
//! Refreshed once a minute: the answer is asked for every full update, which
//! is every second while the face is awake, and the read builds a whole
//! Activity.Info each time.
class ActivityTimer {

    //! Whether the timer was running, paused or stopped at the last reading
    private var _running as Boolean = false;

    private var _reading as MinuteGate;

    //! Constructor
    function initialize() {
        _reading = new MinuteGate();
    }

    //! Read the timer, if the minute has moved on. Once per full update,
    //! before the numerals draw.
    function refresh() as Void {
        if (!_reading.opens()) {
            return;
        }

        _running = readTimer();
    }

    //! Whether an activity is under way, as of the last reading
    //! @return true while the timer is running, paused or stopped short of
    //!         the activity being saved or discarded
    function isRunning() as Boolean {
        return _running;
    }

    //! Ask the system about the timer
    //! @return true while it is anything but off
    private function readTimer() as Boolean {
        // Some watches have no timer state to hand a watch face at all, and
        // naming a member the watch does not carry is an error, not an
        // exception.
        if (!(Activity has :getActivityInfo)) {
            return false;
        }

        var info = Activity.getActivityInfo();

        if ((info == null) || !(info has :timerState)) {
            return false;
        }

        var state = info.timerState;

        return (state != null) && (state != Activity.TIMER_STATE_OFF);
    }
}
