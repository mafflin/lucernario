import Toybox.ActivityMonitor;
import Toybox.Lang;

//! How long until the wearer is recovered from their training, off the
//! activity monitor.
//!
//! Refreshed once a minute: the number moves by the hour, the face asks on
//! every full update, and the read builds a whole ActivityMonitor.Info each
//! time.
class Recovery {

    //! Hours until recovered at the last reading, null when there are none
    private var _hoursLeft as Number? = null;

    private var _reading as MinuteGate;

    //! Constructor
    function initialize() {
        _reading = new MinuteGate();
    }

    //! Read the recovery time, if the minute has moved on. Once per full
    //! update, before the rim marks draw.
    function refresh() as Void {
        if (!_reading.opens()) {
            return;
        }

        _hoursLeft = readHours();
    }

    //! Hours until recovered, as of the last reading. A recovered wearer has
    //! none left, and so does a watch that does not keep the number.
    //! @return The hours left, or null when there are none
    function hoursLeft() as Number? {
        return _hoursLeft;
    }

    //! Ask the activity monitor
    //! @return The hours left, or null when there are none
    private function readHours() as Number? {
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
