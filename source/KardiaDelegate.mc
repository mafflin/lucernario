import Toybox.Application.WatchFaceConfig;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! Receives watch face events from the system: edits made in the native watch
//! face editor, and notice that partial updates cost too much.
class KardiaDelegate extends WatchUi.WatchFaceDelegate {

    //! The view attached to this delegate
    private var _view as KardiaView;

    //! Constructor
    //! @param view The view to apply configuration changes to
    function initialize(view as KardiaView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

    //! Handle watch face configuration changes
    //! @param options The edited configuration
    function onWatchFaceConfigEdited(options as {:configId as WatchFaceConfig.Id, :type as WatchFaceConfigType?, :committed as Boolean}) as Void {
        var id = options[:configId] as WatchFaceConfig.Id?;
        var type = options[:type] as WatchFaceConfigType?;

        if (id == null) {
            return;
        }

        var settings = WatchFaceConfig.getSettings(id);
        if (settings != null) {
            _view.updateConfiguration(settings, type);
        }
    }

    //! Called when onPartialUpdate exceeds the power budget. The system stops
    //! calling it after this, so the view has to stop relying on it.
    //! @param powerInfo How much time was used against the limit
    function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
        System.println("Partial update over budget: " + powerInfo.executionTimeAverage
            + " of " + powerInfo.executionTimeLimit);

        _view.turnPartialUpdatesOff();
    }
}
