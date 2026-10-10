import Toybox.Complications;
import Toybox.Graphics;
import Toybox.Lang;

//! The data fields below the time, side by side and centered as one, so the
//! row stays under the time whatever each shows: where they go, what they
//! show, and the live updates that follow it.
class DataFields {

    //! Between one field's value and the next field's icon, as a share of
    //! the screen width
    private const GAP_RATIO = 0.03;

    private var fields as Array<ComplicationField>;

    private var gap as Number = 0;

    //! What the last draw covered, left, top, right and bottom; null for
    //! nothing
    private var drawnBox as Array<Number>? = null;

    function initialize() {
        fields = [
            new ComplicationField(SlotId.LEFT, Complications.COMPLICATION_TYPE_STEPS),
            new ComplicationField(SlotId.RIGHT, Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY)
        ] as Array<ComplicationField>;
    }

    //! Once per layout: the row from top
    function prepare(dc as Dc, top as Number) as Void {
        var centerY = top + (fields[0].heightIn(dc) / 2);

        gap = (dc.getWidth() * GAP_RATIO).toNumber();

        for (var i = 0; i < fields.size(); i++) {
            fields[i].prepare(dc, centerY);
        }
    }

    function setColor(color as Number) as Void {
        for (var i = 0; i < fields.size(); i++) {
            fields[i].setColor(color);
        }
    }

    //! All but the one in skippedSlot, which the editor draws while it pulses
    //! it; null for none. Every field is placed, that one too.
    function draw(dc as Dc, skippedSlot as Number?) as Void {
        placeContents(dc);
        drawPlaced(dc, skippedSlot);
        drawnBox = contentBox();
    }

    //! The row alone, drawn again over the face it was drawn on: what the
    //! last draw covered is painted background, then the row drawn anew.
    //! Nothing else on the face may lie in the row's box. Returns the box
    //! that changed, null for none.
    function redraw(dc as Dc, skippedSlot as Number?, background as Number) as Array<Number>? {
        placeContents(dc);

        var box = union(drawnBox, contentBox());

        if (box == null) {
            return null;
        }

        dc.setClip(box[0], box[1], box[2] - box[0], box[3] - box[1]);
        dc.setColor(background, background);
        dc.fillRectangle(box[0], box[1], box[2] - box[0], box[3] - box[1]);
        drawPlaced(dc, skippedSlot);
        dc.clearClip();

        drawnBox = contentBox();

        return box;
    }

    //! The field in a slot, null for any other slot
    function fieldFor(slotId as Number?) as ComplicationField? {
        var index = indexOf(slotId);

        return (index != null) ? fields[index] : null;
    }

    //! The slot under a point, or null
    function slotAt(x as Number, y as Number) as Number? {
        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].containsPoint(x, y)) {
                return fields[i].getSlotId();
            }
        }

        return null;
    }

    //! What each field shows, in order
    function shownIds() as Array<Complications.Id> {
        var ids = new [fields.size()] as Array<Complications.Id>;

        for (var i = 0; i < fields.size(); i++) {
            ids[i] = fields[i].getComplicationId();
        }

        return ids;
    }

    //! Whether any field changed
    function refreshShowing(complicationId as Complications.Id) as Boolean {
        var changed = false;

        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].shows(complicationId)) {
                fields[i].refresh();
                changed = true;
            }
        }

        return changed;
    }

    //! Once a minute: the fields whose value moves with the time
    function refreshClocked() as Void {
        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].followsClock()) {
                fields[i].refresh();
            }
        }
    }

    //! Every field read again, for a face that may have missed updates
    function refreshAll() as Void {
        for (var i = 0; i < fields.size(); i++) {
            fields[i].refresh();
        }
    }

    function subscribe() as Void {
        for (var i = 0; i < fields.size(); i++) {
            Complications.subscribeToUpdates(fields[i].getComplicationId());
        }
    }

    //! Live updates follow the picks, previous being shownIds() before them.
    //! A pick another field still shows keeps its updates.
    function follow(previous as Array<Complications.Id>) as Void {
        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].shows(previous[i])) {
                continue;
            }

            if (!isShown(previous[i])) {
                Complications.unsubscribeFromUpdates(previous[i]);
            }

            Complications.subscribeToUpdates(fields[i].getComplicationId());
        }
    }

    //! Side by side, a gap between those that show anything, centered as one
    private function placeContents(dc as Dc) as Void {
        var count = fields.size();
        var widths = new [count] as Array<Number>;
        var total = 0;
        var shown = 0;

        for (var i = 0; i < count; i++) {
            widths[i] = fields[i].contentWidth(dc);

            if (widths[i] > 0) {
                total += widths[i];
                shown++;
            }
        }

        if (shown > 1) {
            total += gap * (shown - 1);
        }

        var left = Dial.centerX - (total / 2);

        for (var i = 0; i < count; i++) {
            fields[i].placeContent(left, widths[i]);

            if (widths[i] > 0) {
                left += widths[i] + gap;
            }
        }
    }

    //! As placed: all but the one in skippedSlot
    private function drawPlaced(dc as Dc, skippedSlot as Number?) as Void {
        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].getSlotId() != skippedSlot) {
                fields[i].draw(dc);
            }
        }
    }

    //! Every field's icon and value as placed, one box; null for nothing
    private function contentBox() as Array<Number>? {
        var box = null as Array<Number>?;

        for (var i = 0; i < fields.size(); i++) {
            box = union(box, fields[i].contentBox());
        }

        return box;
    }

    //! The box round both, either of which may be null
    private function union(first as Array<Number>?, second as Array<Number>?) as Array<Number>? {
        if (first == null) {
            return second;
        }

        if (second == null) {
            return first;
        }

        return [
            Numbers.min(first[0], second[0]),
            Numbers.min(first[1], second[1]),
            Numbers.max(first[2], second[2]),
            Numbers.max(first[3], second[3])
        ];
    }

    private function indexOf(slotId as Number?) as Number? {
        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].getSlotId() == slotId) {
                return i;
            }
        }

        return null;
    }

    private function isShown(complicationId as Complications.Id) as Boolean {
        for (var i = 0; i < fields.size(); i++) {
            if (fields[i].shows(complicationId)) {
                return true;
            }
        }

        return false;
    }
}
