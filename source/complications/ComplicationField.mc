import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! A data container below the time: whichever complication the user picked
//! in the editor, its icon and its value as its FieldKind shows them. A
//! Drawable so the editor can pulse it in place. DataFields says where its
//! icon and value start, each draw.
class ComplicationField extends WatchUi.Drawable {

    //! Fixed, so a short value still leaves a tap target; a quarter of the
    //! screen, centered on what the field shows
    private const WIDTH_RATIO = 0.25;

    //! Past the icon and value on every side, for the smoothed edges
    private const PADDING = 2;

    //! Matches the slot id in watchface.xml
    private var slotId as Number;

    private var complicationId as Complications.Id;
    private var text as String = "";

    //! How the type is shown, made again only when the type moves; null
    //! while nothing is known
    private var kind as FieldKind? = null;
    private var kindType as Complications.Type? = null;
    private var color as Number = Graphics.COLOR_WHITE;

    //! Where the icon and value start, and how wide they are, as of the last
    //! placement
    private var contentLeft as Number = 0;
    private var placedWidth as Number = 0;

    //! defaultType shows until the user picks one
    function initialize(slotId as Number, defaultType as Complications.Type) {
        Drawable.initialize({ :identifier => slotId });

        self.slotId = slotId;
        complicationId = new Complications.Id(defaultType);
    }

    //! Once per layout: the row's height; across, placeContent() says
    function prepare(dc as Dc, centerY as Number) as Void {
        width = widthIn(dc);
        height = heightIn(dc);
        locX = Dial.centerX - (width / 2);
        locY = (centerY - (height / 2)).toNumber();
        contentLeft = Dial.centerX;
    }

    //! How wide the icon and value are now
    function contentWidth(dc as Dc) as Number {
        var shown = kind;

        return IconText.widthOf(dc, (shown != null) ? shown.icon() : null, text);
    }

    //! The icon and value from left, the tap target centered on them
    function placeContent(left as Number, contentWidth as Number) as Void {
        contentLeft = left;
        placedWidth = contentWidth;
        locX = left + (contentWidth / 2) - (width.toNumber() / 2);
    }

    function heightIn(dc as Dc) as Number {
        return IconText.heightIn(dc);
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

    function setColor(color as Number) as Void {
        self.color = color;
    }

    function shows(other as Complications.Id) as Boolean {
        return complicationId.equals(other);
    }

    function followsClock() as Boolean {
        var shown = kind;

        return (shown != null) && shown.followsClock();
    }

    //! Read the complication's current value
    function refresh() as Void {
        var complication = ComplicationReader.read(complicationId);

        if (complication == null) {
            text = ValueFormat.NOTHING;
            kind = null;
            kindType = null;
            return;
        }

        text = kindOf(complication.getType()).text(complication);
    }

    //! Also drawn by the editor while it pulses the field
    function draw(dc as Dc) as Void {
        var shown = kind;

        if (shown == null) {
            IconText.draw(dc, contentLeft, locY.toNumber(), null, text, color, color);
            return;
        }

        IconText.draw(dc, contentLeft, locY.toNumber(), shown.icon(), text, color, shown.iconTint(color));
    }

    //! The pixels the icon and value cover as last placed, left, top, right
    //! and bottom; null for nothing
    function contentBox() as Array<Number>? {
        if (placedWidth <= 0) {
            return null;
        }

        var top = locY.toNumber();
        var bottom = top + height.toNumber();
        var shown = kind;
        var icon = (shown != null) ? shown.icon() : null;

        if (icon != null) {
            var iconTop = IconText.iconTop(top, icon);

            top = Numbers.min(top, iconTop);
            bottom = Numbers.max(bottom, iconTop + icon.height());
        }

        return [contentLeft - PADDING, top - PADDING, contentLeft + placedWidth + PADDING, bottom + PADDING];
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

    private function widthIn(dc as Dc) as Number {
        return (dc.getWidth() * WIDTH_RATIO).toNumber();
    }

    //! The kind for a type, kept until the type moves
    private function kindOf(type as Complications.Type?) as FieldKind {
        var current = kind;

        if ((current != null) && (type == kindType)) {
            return current;
        }

        current = FieldKinds.of(type);
        kind = current;
        kindType = type;

        return current;
    }
}
