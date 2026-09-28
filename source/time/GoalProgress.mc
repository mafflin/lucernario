import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

//! Progress to the goal picked in the goal slot
class GoalProgress {

    private var goalType as Complications.Type = Complications.COMPLICATION_TYPE_STEPS;
    private var shareDone as Float? = null;

    //! For a new pick before the next reading
    private var lastInfo as ActivityMonitor.Info? = null;

    function initialize() {
    }

    //! Anything unknown reads as steps
    function setType(type as Complications.Type) as Void {
        if (type == goalType) {
            return;
        }

        goalType = type;

        var info = lastInfo;

        if (info != null) {
            shareDone = shareIn(info);
        }
    }

    function read(info as ActivityMonitor.Info) as Void {
        lastInfo = info;
        shareDone = shareIn(info);
    }

    //! 0 to 1; null without a goal
    function share() as Float? {
        return shareDone;
    }

    private function shareIn(info as ActivityMonitor.Info) as Float? {
        if (goalType == Complications.COMPLICATION_TYPE_FLOORS_CLIMBED) {
            return shareOf(info.floorsClimbed, info.floorsClimbedGoal);
        }

        // Weekly
        if (goalType == Complications.COMPLICATION_TYPE_INTENSITY_MINUTES) {
            var minutes = info.activeMinutesWeek;

            if (minutes == null) {
                return null;
            }

            return shareOf(minutes.total, info.activeMinutesWeekGoal);
        }

        return shareOf(info.steps, info.stepGoal);
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
