import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! AM or PM, shown only on a watch set to a 12 hour clock.
class Meridiem extends Icon {

    private const _MORNING = 0;
    private const _AFTERNOON = 1;

    //! Hours on a 12 hour clock face
    private const _HOURS_PER_HALF_DAY = 12;

    private var _images as Array<ResourceId> = [
        Rez.Drawables.Am,
        Rez.Drawables.Pm
    ];

    private var _morning as Boolean = true;

    //! Constructor. No single resource: bitmap() picks the half of the day.
    function initialize() {
        Icon.initialize(null);
    }

    //! Answering the 24 hour case first keeps a watch that has no use for
    //! this from ever reading the clock or loading a bitmap. Past that the
    //! half is settled once a full update, not on every bitmap() call, since
    //! the row asks for the size several times.
    //! @param settings The device settings
    //! @return true on a 12 hour watch
    function on(settings as System.DeviceSettings) as Boolean {
        if (settings.is24Hour) {
            return false;
        }

        _morning = (System.getClockTime().hour < _HOURS_PER_HALF_DAY);

        return true;
    }

    //! The bitmap for this half of the day
    //! @return The bitmap
    protected function bitmap() as BitmapResource {
        return choose(_images, _morning ? _MORNING : _AFTERNOON);
    }
}
