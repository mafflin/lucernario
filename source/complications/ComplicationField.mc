import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The data container below the time: whichever complication the user
//! picked in the editor. A Drawable so the editor can pulse it in place.
class ComplicationField extends WatchUi.Drawable {

    private const _LABEL_FORMAT = "$1$ $2$";
    private const _FONT = Graphics.FONT_SMALL;

    //! Fixed, so the tap target does not shift as values change
    private const _WIDTH_RATIO = 0.6;

    //! Matches the slot id in watchface.xml
    private var _location as Number;

    private var _complicationId as Complications.Id;
    private var _text as String = "";
    private var _color as Number = Graphics.COLOR_WHITE;

    //! defaultType shows until the user picks one
    function initialize(location as Number, defaultType as Complications.Type) {
        Drawable.initialize({ :identifier => location });

        _location = location;
        _complicationId = new Complications.Id(defaultType);
    }

    //! Once per layout
    function prepare(dc as Dc, centerX as Number, centerY as Number) as Void {
        width = (dc.getWidth() * _WIDTH_RATIO).toNumber();
        height = heightIn(dc);
        locX = (centerX - (width / 2)).toNumber();
        locY = (centerY - (height / 2)).toNumber();
    }

    function heightIn(dc as Dc) as Number {
        return dc.getFontHeight(_FONT);
    }

    function getLocation() as Number {
        return _location;
    }

    function getComplicationId() as Complications.Id {
        return _complicationId;
    }

    function setComplicationId(complicationId as Complications.Id) as Void {
        _complicationId = complicationId;
    }

    function shows(complicationId as Complications.Id) as Boolean {
        return _complicationId.equals(complicationId);
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Read the complication's current value
    function refresh() as Void {
        // Some watches throw on a complication they do not carry.
        try {
            var complication = Complications.getComplication(_complicationId);

            _text = labelled(
                ComplicationLabel.of(complication.getType()),
                ComplicationFormat.text(complication)
            );
        } catch (exception) {
            _text = "";
        }
    }

    function draw(dc as Dc) as Void {
        // Hidden while the editor pulses it, so it is not drawn twice.
        if (!isVisible) {
            return;
        }

        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            locX + (width / 2),
            locY,
            _FONT,
            _text,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    //! What the editor outlines and taps are tested against
    function getBoundingBox() as Graphics.BoundingBox {
        var boundingBox = new Graphics.BoundingBox();
        boundingBox.addRectangle(locX.toNumber(), locY.toNumber(), width.toNumber(), height.toNumber());

        return boundingBox;
    }

    function containsPoint(x as Number, y as Number) as Boolean {
        return getBoundingBox().includesPoint(x, y);
    }

    //! The value behind its label, or alone for a type that needs none
    private function labelled(label as String, value as String) as String {
        if (label.length() == 0) {
            return value;
        }

        return Lang.format(_LABEL_FORMAT, [label, value]);
    }
}
