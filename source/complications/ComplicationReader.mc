import Toybox.Complications;
import Toybox.Lang;

//! The one place a complication is read: some watches throw on a
//! complication they do not carry.
module ComplicationReader {

    //! Null on a watch without it
    function read(id as Complications.Id) as Complications.Complication? {
        try {
            return Complications.getComplication(id);
        } catch (exception) {
            return null;
        }
    }

    //! Null on a watch without it, or with nothing to report
    function valueOf(id as Complications.Id) as Complications.Value? {
        var complication = read(id);

        return (complication != null) ? complication.value : null;
    }
}
