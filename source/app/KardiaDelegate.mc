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

    //! Hand the system the drawable for the complication slot the editor is
    //! working on, so it can pulse that container in place
    //! @param complication The slot the editor is working on
    //! @return A reference to that container's drawable
    function getComplicationDrawable(complication as ComplicationRef) as Drawable or ComplicationDrawableRef or Null {
        return _view.getComplication(complication);
    }

    //! Tell the system which complication slot was tapped, so it can open the
    //! picker for it
    //! @param clickEvent The tap
    //! @return true when a container was tapped
    function onTap(clickEvent as ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        var location = _view.getTappedComplication(coordinates[0], coordinates[1]);

        if (location == null) {
            return false;
        }

        setSelectedComplication(location);
        return true;
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
