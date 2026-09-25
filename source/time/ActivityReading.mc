import Toybox.ActivityMonitor;
import Toybox.Lang;

//! The activity monitor, read once a minute and shared
class ActivityReading {

    private var _reading as MinuteGate;

    function initialize() {
        _reading = new MinuteGate();
    }

    //! The new Info, or null within the minute
    function refresh() as ActivityMonitor.Info? {
        if (!_reading.opens()) {
            return null;
        }

        return ActivityMonitor.getInfo();
    }
}
