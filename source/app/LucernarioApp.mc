import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Digital watch face: the time, as large as the screen allows.
class LucernarioApp extends Application.AppBase {

    //! Whether the native watch face editor started the face
    private var _editMode as Boolean = false;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        if (state != null) {
            var launched = state[:launchedFromWatchFaceSettingsEditor];
            _editMode = (launched instanceof Boolean) ? (launched as Boolean) : false;
        }
    }

    function onStop(state as Dictionary?) as Void {
    }

    //! The delegate carries editor edits and the power budget notice, which
    //! can arrive at any time, so it is always attached.
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new LucernarioView(_editMode);

        if (WatchUi has :WatchFaceDelegate) {
            return [ view, new LucernarioDelegate(view) ];
        }

        return [ view ];
    }
}
