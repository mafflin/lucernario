import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

//! Progress to the goal picked in the goal slot
class GoalProgress {

    private var _type as Complications.Type = Complications.COMPLICATION_TYPE_STEPS;
    private var _share as Float? = null;

    //! For a new pick before the next reading
    private var _info as ActivityMonitor.Info? = null;

    function initialize() {
    }

    //! Anything unknown reads as steps
    function setType(type as Complications.Type) as Void {
        if (type == _type) {
            return;
        }

        _type = type;

        var info = _info;

        if (info != null) {
            _share = shareIn(info);
        }
    }

    function read(info as ActivityMonitor.Info) as Void {
        _info = info;
        _share = shareIn(info);
    }

    //! 0 to 1; null without a goal
    function share() as Float? {
        return _share;
    }

    private function shareIn(info as ActivityMonitor.Info) as Float? {
        if (_type == Complications.COMPLICATION_TYPE_FLOORS_CLIMBED) {
            return shareOf(info.floorsClimbed, info.floorsClimbedGoal);
        }

        // Weekly
        if (_type == Complications.COMPLICATION_TYPE_INTENSITY_MINUTES) {
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
