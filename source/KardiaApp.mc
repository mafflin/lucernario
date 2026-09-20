import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Digital watch face that shows the time, as large as the screen allows.
class KardiaApp extends Application.AppBase {

    //! Constructor
    function initialize() {
        AppBase.initialize();
    }

    //! Handle app startup
    //! @param state Startup arguments
    function onStart(state as Dictionary?) as Void {
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
    //! @return Array [KardiaView] or [KardiaView, KardiaDelegate]
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new KardiaView();

        if (WatchUi has :WatchFaceDelegate) {
            return [ view, new KardiaDelegate(view) ];
        }

        return [ view ];
    }
}
