import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! One of the data containers below the time. Shows whatever complication
//! the user has assigned to this slot in the native watch face editor.
//!
//! It is a Drawable because the editor asks for one when the user is picking
//! a complication, so it can pulse the field in place.
class ComplicationField extends WatchUi.Drawable {

    //! How the label and the value sit together
    private const _LABEL_FORMAT = "$1$ $2$";

    //! The font the container is drawn in
    private const _FONT = Graphics.FONT_SMALL;

    //! Width of the slot as a fraction of the screen width. Fixed, so the
    //! tap target and the editor's outline do not shift as values change.
    private const _WIDTH_RATIO = 0.6;

    //! Which slot this is, matching the ids in watchface.xml
    private var _location as Number;


    //! The complication assigned to this slot
    private var _complicationId as Complications.Id;

    //! The value to draw
    private var _text as String = "";

    //! The color the value is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Constructor
    //! @param location Which slot this is, from FieldLocation
    //! @param defaultType The complication shown until the user picks one
    function initialize(location as Number, defaultType as Complications.Type) {
        Drawable.initialize({ :identifier => location });

        _location = location;
        _complicationId = new Complications.Id(defaultType);
    }

    //! Place this field on the screen. Call once per layout.
    //! @param dc The drawing context
    //! @param centerX Where the middle of the slot sits horizontally
    //! @param centerY Where the middle of the slot sits vertically
    function prepare(dc as Dc, centerX as Number, centerY as Number) as Void {
        width = (dc.getWidth() * _WIDTH_RATIO).toNumber();
        height = dc.getFontHeight(_FONT);
        locX = (centerX - (width / 2)).toNumber();
        locY = (centerY - (height / 2)).toNumber();
    }

    //! How tall a field is on this screen, before it has been placed
    //! @param dc The drawing context
    //! @return The height in pixels
    function heightIn(dc as Dc) as Number {
        return dc.getFontHeight(_FONT);
    }

    //! Which slot this is
    //! @return The FieldLocation value
    function getLocation() as Number {
        return _location;
    }

    //! The complication currently assigned to this slot
    //! @return The complication id
    function getComplicationId() as Complications.Id {
        return _complicationId;
    }

    //! Assign a complication to this slot
    //! @param complicationId The complication the user picked
    function setComplicationId(complicationId as Complications.Id) as Void {
        _complicationId = complicationId;
    }

    //! Whether this slot shows the given complication
    //! @param complicationId The complication to compare against
    //! @return true when they match
    function shows(complicationId as Complications.Id) as Boolean {
        return _complicationId.equals(complicationId);
    }

    //! Read the current value of the assigned complication
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

    //! The value behind its label, or on its own for a type whose value
    //! already reads as what it is
    //! @param label The short name for the type
    //! @param value The formatted value
    //! @return The text to draw
    private function labelled(label as String, value as String) as String {
        if (label.length() == 0) {
            return value;
        }

        return Lang.format(_LABEL_FORMAT, [label, value]);
    }

    //! Set the color the value is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw the field
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        // The view hides the field the editor is currently pulsing, so it is
        // not drawn twice in two places.
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

    //! The box the editor outlines and taps are tested against
    //! @return The bounding box for this field
    function getBoundingBox() as Graphics.BoundingBox {
        var boundingBox = new Graphics.BoundingBox();
        boundingBox.addRectangle(locX.toNumber(), locY.toNumber(), width.toNumber(), height.toNumber());

        return boundingBox;
    }

    //! Whether the given point falls inside this field
    //! @param x The x coordinate
    //! @param y The y coordinate
    //! @return true when the point is inside
    function containsPoint(x as Number, y as Number) as Boolean {
        return getBoundingBox().includesPoint(x, y);
    }
}
