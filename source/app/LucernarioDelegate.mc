import Toybox.Application.WatchFaceConfig;
import Toybox.Lang;
import Toybox.WatchUi;

//! System events: editor edits, complication taps, and the power budget
//! notice for partial updates.
class LucernarioDelegate extends WatchUi.WatchFaceDelegate {

    private var _view as LucernarioView;

    function initialize(view as LucernarioView) {
        WatchFaceDelegate.initialize();
        _view = view;
    }

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

    //! The drawable the editor pulses while the user picks a complication
    function getComplicationDrawable(complication as ComplicationRef) as Drawable or ComplicationDrawableRef or Null {
        return _view.getComplication(complication);
    }

    //! A tap on a container opens the picker for it
    function onTap(clickEvent as ClickEvent) as Boolean {
        var coordinates = clickEvent.getCoordinates();
        var location = _view.getTappedComplication(coordinates[0], coordinates[1]);

        if (location == null) {
            return false;
        }

        setSelectedComplication(location);
        return true;
    }

    //! The system stops calling onPartialUpdate after this
    function onPowerBudgetExceeded(powerInfo as WatchFacePowerInfo) as Void {
        _view.turnPartialUpdatesOff();
    }
}
