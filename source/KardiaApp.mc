import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Digital watch face that shows the time, as large as the screen allows.
class KardiaApp extends Application.AppBase {

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
            var editorActive = state[:launchedFromWatchFaceSettingsEditor] as Boolean?;
            if (editorActive) {
                _editMode = true;
            }
        }
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view for the app. The delegate is only needed while
    //! the native watch face editor is running.
    //! @return Array [KardiaView] or [KardiaView, KardiaDelegate]
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new KardiaView();

        if (_editMode) {
            return [ view, new KardiaDelegate(view) ];
        }

        return [ view ];
    }
}
