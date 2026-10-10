import Toybox.Complications;
import Toybox.Lang;

//! Today's high and low: the one type the system formats itself, as
//! "H 21 / L 12" or similar, with no degree marks. One is put after each
//! number.
class HighLowKind extends FieldKind {

    function initialize(resourceId as ResourceId?) {
        FieldKind.initialize(resourceId);
    }

    protected function format(value as Complications.Value, complication as Complications.Complication) as String {
        if (!(value instanceof Lang.String)) {
            // A watch that hands over one number instead of the pair.
            return ValueFormat.whole(value) + ValueFormat.DEGREE;
        }

        var characters = value.toCharArray();
        var text = ValueFormat.NOTHING;

        for (var i = 0; i < characters.size(); i++) {
            text += characters[i].toString();

            if (endsNumber(characters, i)) {
                text += ValueFormat.DEGREE;
            }
        }

        return text;
    }

    //! Whether a degree mark belongs after this character
    private function endsNumber(characters as Array<Char>, i as Number) as Boolean {
        if (!isDigit(characters[i])) {
            return false;
        }

        var next = i + 1;

        if (next >= characters.size()) {
            return true;
        }

        if (isDigit(characters[next])) {
            return false;
        }

        // A separator with digits behind it is inside the number: 21.5 takes
        // one mark.
        return !(isSeparator(characters[next])
            && ((next + 1) < characters.size())
            && isDigit(characters[next + 1]));
    }

    private function isDigit(character as Char) as Boolean {
        return (character >= '0') && (character <= '9');
    }

    private function isSeparator(character as Char) as Boolean {
        return (character == '.') || (character == ',');
    }
}
