import Toybox.Application.WatchFaceConfig;
import Toybox.Lang;
import Toybox.WatchUi;

//! Receives configuration changes made in the native watch face editor.
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
}
