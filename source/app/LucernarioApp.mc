import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Digital watch face that shows the time, as large as the screen allows.
class LucernarioApp extends Application.AppBase {

    //! Whether the watch face was started by the native watch face editor
    private var _editMode as Boolean = false;

    //! Constructor
    function initialize() {
        AppBase.initialize();
    }

    //! Handle app startup
    //! @param state Startup arguments
    function onStart(state as Dictionary?) as Void {
        if (state != null) {
            var launched = state[:launchedFromWatchFaceSettingsEditor];
            _editMode = (launched instanceof Boolean) ? (launched as Boolean) : false;
        }
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view for the app.
    //!
    //! The delegate is always attached: it carries both the edits made in the
    //! native watch face editor and the power budget notice for partial
    //! updates, and the latter can arrive at any time.
    //! @return Array [LucernarioView] or [LucernarioView, LucernarioDelegate]
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new LucernarioView(_editMode);

        if (WatchUi has :WatchFaceDelegate) {
            return [ view, new LucernarioDelegate(view) ];
        }

        return [ view ];
    }
}
