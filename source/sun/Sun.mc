import Toybox.Lang;

//! The one Daylight, for everything that goes by the sun: the dial's colors,
//! the sun field and the weather's night icons. The view refreshes it before
//! each draw; the rest only read it.
module Sun {

    //! Made on the first ask
    var shared as Daylight? = null;

    function daylight() as Daylight {
        if (shared == null) {
            shared = new Daylight();
        }

        return shared as Daylight;
    }
}
