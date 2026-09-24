import Toybox.Activity;
import Toybox.Lang;

//! Whether an activity is under way: the system puts its own indicator at
//! the top of the screen while one is, over whatever the face drew there.
//!
//! Read off the activity timer, which a watch face may or may not be told
//! about depending on the device. Anything short of a clear answer counts as
//! no activity. The stopwatch is not an activity and does not show here.
module ActivityTimer {

    //! Whether the activity timer is running, paused or stopped short of
    //! the activity being saved or discarded
    //! @return true while an activity is under way
    function isRunning() as Boolean {
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
