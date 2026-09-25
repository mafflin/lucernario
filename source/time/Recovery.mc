import Toybox.ActivityMonitor;
import Toybox.Lang;

//! Hours until recovered
class Recovery {

    private var _hoursLeft as Number? = null;

    function initialize() {
    }

    function read(info as ActivityMonitor.Info) as Void {
        _hoursLeft = readHours(info);
    }

    //! null when recovered, or when the watch does not keep the number
    function hoursLeft() as Number? {
        return _hoursLeft;
    }

    private function readHours(info as ActivityMonitor.Info) as Number? {
        // Naming a member the watch lacks is an error, not an exception.
        if (!(info has :timeToRecovery)) {
            return null;
        }

        var left = info.timeToRecovery;

        if ((left == null) || (left <= 0)) {
            return null;
        }

        return left;
    }
}
