import Toybox.ActivityMonitor;
import Toybox.Lang;

//! How long until the wearer is recovered from their training, off the
//! activity monitor.
module Recovery {

    //! Hours until recovered. A recovered wearer has none left, and so does a
    //! watch that does not keep the number.
    //! @return The hours left, or null when there are none
    function hoursLeft() as Number? {
        var info = ActivityMonitor.getInfo();

        // Naming a member the watch does not carry is an error, not an
        // exception.
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
