import Toybox.ActivityMonitor;
import Toybox.Lang;

//! Progress to the day's steps goal, read once a minute
class GoalProgress {

    private var shareDone as Float? = null;
    private var minuteGate as MinuteGate;

    function initialize() {
        minuteGate = new MinuteGate();
    }

    //! Once per full update
    function refresh() as Void {
        if (!minuteGate.opens()) {
            return;
        }

        var info = ActivityMonitor.getInfo();

        shareDone = shareOf(info.steps, info.stepGoal);
    }

    //! 0 to 1; null without a goal
    function share() as Float? {
        return shareDone;
    }

    private function shareOf(value as Number?, goal as Number?) as Float? {
        if ((value == null) || (goal == null) || (goal <= 0)) {
            return null;
        }

        if (value >= goal) {
            return 1.0;
        }

        return value.toFloat() / goal;
    }
}
