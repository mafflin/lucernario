import Toybox.ActivityMonitor;
import Toybox.Lang;

//! Hours until recovered, off the activity monitor. Read once a minute: the
//! read builds a whole ActivityMonitor.Info.
class Recovery {

    private var _hoursLeft as Number? = null;
    private var _reading as MinuteGate;

    function initialize() {
        _reading = new MinuteGate();
    }

    //! Once per full update
    function refresh() as Void {
        if (!_reading.opens()) {
            return;
        }

        _hoursLeft = readHours();
    }

    //! null when recovered, or when the watch does not keep the number
    function hoursLeft() as Number? {
        return _hoursLeft;
    }

    private function readHours() as Number? {
        var info = ActivityMonitor.getInfo();

        // Naming a member the watch lacks is an error, not an exception.
        if ((info == null) || !(info has :timeToRecovery)) {
            return null;
        }

        var left = info.timeToRecovery;

        if ((left == null) || (left <= 0)) {
            return null;
        }

        return left;
    }
}
