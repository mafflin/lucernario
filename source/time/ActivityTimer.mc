import Toybox.Activity;
import Toybox.Lang;

//! Whether an activity is under way, off the activity timer. The system's
//! indicator sits over the top of the face while one is. Not every watch
//! hands a face the timer; anything unclear counts as no activity. The
//! stopwatch is not an activity. Read once a minute: the read builds a whole
//! Activity.Info.
class ActivityTimer {

    private var running as Boolean = false;
    private var minuteGate as MinuteGate;

    function initialize() {
        minuteGate = new MinuteGate();
    }

    //! Once per full update
    function refresh() as Void {
        if (!minuteGate.opens()) {
            return;
        }

        running = readTimer();
    }

    //! Running, paused or stopped short of being saved or discarded
    function isRunning() as Boolean {
        return running;
    }

    private function readTimer() as Boolean {
        // Naming a member the watch lacks is an error, not an exception.
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
