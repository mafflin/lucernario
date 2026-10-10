import Toybox.Complications;
import Toybox.Lang;

//! How a data field shows one kind of complication: its icon, and its value
//! as text. This base shows the value as the system gives it, with any unit
//! it supplies as a string; a subclass formats its own kind. FieldKinds
//! picks one per type.
class FieldKind {

    private var fieldIcon as Icon?;

    //! resourceId null for no icon
    function initialize(resourceId as ResourceId?) {
        fieldIcon = (resourceId != null) ? new Icon(resourceId) : null;
    }

    function icon() as Icon? {
        return fieldIcon;
    }

    //! The icon's color, given the data color the value keeps. Overridden by
    //! a kind that says something with color.
    function iconTint(color as Number) as Number {
        return color;
    }

    //! Whether the value moves with the time as well as with the system's
    //! updates, and so is read again every minute. Overridden.
    function followsClock() as Boolean {
        return false;
    }

    //! Empty when the system has no value
    function text(complication as Complications.Complication) as String {
        var value = complication.value;

        return (value != null) ? format(value, complication) : ValueFormat.NOTHING;
    }

    //! Overridden per kind
    protected function format(value as Complications.Value, complication as Complications.Complication) as String {
        return ValueFormat.withUnit(value, complication.unit);
    }
}
