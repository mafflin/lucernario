import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

//! The wind in the status row: a ring with a wedge in it pointing where the
//! wind goes, one bitmap to each eighth of the compass, strength said with
//! color - see WindReading. The ring alone when the wind is unknown or calm.
class Wind extends Icon {

    //! An eighth of the compass, in degrees
    private const EIGHTH = 45;
    private const EIGHTHS = 8;

    //! One per eighth, clockwise from north, named for where the wind comes
    //! from
    private var images as Array<ResourceId> = [
        Rez.Drawables.WindN,
        Rez.Drawables.WindNe,
        Rez.Drawables.WindE,
        Rez.Drawables.WindSe,
        Rez.Drawables.WindS,
        Rez.Drawables.WindSw,
        Rez.Drawables.WindW,
        Rez.Drawables.WindNw
    ];

    //! No direction to point
    private var calmImage as ResourceId = Rez.Drawables.WindCalm;

    //! Its own: nothing else reads the wind's strength
    private var windReading as WindReading;

    function initialize() {
        Icon.initialize(null);
        windReading = new WindReading();
    }

    //! Always shown, the ring alone for no wind. Read here, once a minute:
    //! the row asks every icon before it draws.
    function isReporting(settings as System.DeviceSettings) as Boolean {
        windReading.refresh();

        return true;
    }

    protected function bitmap() as BitmapResource {
        var bearing = windReading.bearing();

        if ((bearing == null) || windReading.isCalm()) {
            return chooseResource(calmImage);
        }

        return choose(images, eighthOf(bearing));
    }

    protected function tint() as Number {
        return windReading.colorFor(Icon.tint());
    }

    //! The nearest eighth
    private function eighthOf(bearing as Number) as Number {
        return ((bearing + (EIGHTH / 2)) / EIGHTH) % EIGHTHS;
    }
}
