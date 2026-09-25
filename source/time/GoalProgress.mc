import Toybox.ActivityMonitor;
import Toybox.Complications;
import Toybox.Lang;

//! Progress to the goal picked in the editor's goal slot, as a share of it,
//! off the activity monitor. Read once a minute: the read builds a whole
//! ActivityMonitor.Info.
class GoalProgress {

    private var _type as Complications.Type = Complications.COMPLICATION_TYPE_STEPS;
    private var _share as Float? = null;
    private var _reading as MinuteGate;

    //! Read on the next refresh whatever the minute, for a new pick
    private var _stale as Boolean = true;

    function initialize() {
        _reading = new MinuteGate();
    }

    //! Steps, floors or intensity minutes; anything else reads as steps
    function setType(type as Complications.Type) as Void {
        if (type != _type) {
            _type = type;
            _stale = true;
        }
    }

    //! Once per full update
    function refresh() as Void {
        if (!_reading.opens() && !_stale) {
            return;
        }

        _stale = false;
        _share = readShare();
    }

    //! 0 to 1, held at 1 past the goal; null when the watch has no goal
    function share() as Float? {
        return _share;
    }

    private function readShare() as Float? {
        var info = ActivityMonitor.getInfo();

        if (info == null) {
            return null;
        }

        if (_type == Complications.COMPLICATION_TYPE_FLOORS_CLIMBED) {
            return shareOf(info.floorsClimbed, info.floorsClimbedGoal);
        }

        // A weekly goal, unlike the others
        if (_type == Complications.COMPLICATION_TYPE_INTENSITY_MINUTES) {
            var minutes = info.activeMinutesWeek;

            return (minutes == null) ? null : shareOf(minutes.total, info.activeMinutesWeekGoal);
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
