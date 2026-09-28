import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! The data container below the time: whichever complication the user
//! picked in the editor. A Drawable so the editor can pulse it in place.
class ComplicationField extends WatchUi.Drawable {

    private const LABEL_FORMAT = "$1$ $2$";
    private const FONT = Graphics.FONT_SMALL;

    //! Fixed, so the tap target does not shift as values change
    private const WIDTH_RATIO = 0.6;

    //! Matches the slot id in watchface.xml
    private var slotId as Number;

    private var complicationId as Complications.Id;
    private var text as String = "";
    private var color as Number = Graphics.COLOR_WHITE;

    //! defaultType shows until the user picks one
    function initialize(slotId as Number, defaultType as Complications.Type) {
        Drawable.initialize({ :identifier => slotId });

        self.slotId = slotId;
        complicationId = new Complications.Id(defaultType);
    }

    //! Once per layout
    function prepare(dc as Dc, centerX as Number, centerY as Number) as Void {
        width = (dc.getWidth() * WIDTH_RATIO).toNumber();
        height = heightIn(dc);
        locX = (centerX - (width / 2)).toNumber();
        locY = (centerY - (height / 2)).toNumber();
    }

    function heightIn(dc as Dc) as Number {
        return dc.getFontHeight(FONT);
    }

    function getSlotId() as Number {
        return slotId;
    }

    function getComplicationId() as Complications.Id {
        return complicationId;
    }

    function setComplicationId(complicationId as Complications.Id) as Void {
        self.complicationId = complicationId;
    }

    function shows(other as Complications.Id) as Boolean {
        return complicationId.equals(other);
    }

    function setColor(color as Number) as Void {
        self.color = color;
    }

    //! Read the complication's current value
    function refresh() as Void {
        // Some watches throw on a complication they do not carry.
        try {
            var complication = Complications.getComplication(complicationId);

            text = labelled(
                ComplicationLabel.of(complication.getType()),
                ComplicationFormat.text(complication)
            );
        } catch (exception) {
            text = "";
        }
    }

    function draw(dc as Dc) as Void {
        // Hidden while the editor pulses it, so it is not drawn twice.
        if (!isVisible) {
            return;
        }

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            locX + (width / 2),
            locY,
            FONT,
            text,
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

        return Lang.format(LABEL_FORMAT, [label, value]);
    }
}
