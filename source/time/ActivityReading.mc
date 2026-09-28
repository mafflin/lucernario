import Toybox.ActivityMonitor;
import Toybox.Lang;

//! The activity monitor, read once a minute and shared
class ActivityReading {

    private var minuteGate as MinuteGate;

    function initialize() {
        minuteGate = new MinuteGate();
    }

    //! The new Info, or null within the minute
    function refresh() as ActivityMonitor.Info? {
        if (!minuteGate.opens()) {
            return null;
        }

        return ActivityMonitor.getInfo();
    }
}
