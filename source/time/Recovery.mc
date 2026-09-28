import Toybox.ActivityMonitor;
import Toybox.Lang;

//! Hours until recovered
class Recovery {

    private var hoursToRecover as Number? = null;

    function initialize() {
    }

    function read(info as ActivityMonitor.Info) as Void {
        hoursToRecover = readHours(info);
    }

    //! null when recovered, or when the watch does not keep the number
    function hoursLeft() as Number? {
        return hoursToRecover;
    }

    private function readHours(info as ActivityMonitor.Info) as Number? {
        // Naming a member the watch lacks is an error, not an exception.
        if (!(info has :timeToRecovery)) {
            return null;
        }

        var timeToRecovery = info.timeToRecovery;

        if ((timeToRecovery == null) || (timeToRecovery <= 0)) {
            return null;
        }

        return timeToRecovery;
    }
}
