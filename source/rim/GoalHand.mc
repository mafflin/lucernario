import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! A dot going round once to the goal, a few pixels inside the hour marks.
//! A ring until the goal is done, solid once it is, back at the 12.
class GoalHand extends WatchUi.Drawable {

    //! Air between the dot and the hour marks' pen ends
    private const MARK_GAP = 4;
    private const MIN_RADIUS = 2;

    //! The ring's width, as a share of the dot's radius, at least MIN_RING
    private const RING_DIVISOR = 2;
    private const MIN_RING = 2;

    private var progress as GoalProgress;
    private var color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare(): the dot's size, and the circle its center runs on
    private var dotRadius as Number = MIN_RADIUS;
    private var ringWidth as Number = MIN_RING;
    private var orbitRadius as Number = 0;

    //! As last drawn; empty when not shown
    private var dotX as Number = 0;
    private var dotY as Number = 0;
    private var isDone as Boolean = false;
    private var box as Box;

    function initialize(progress as GoalProgress) {
        Drawable.initialize({ :identifier => SlotId.GOAL });

        self.progress = progress;
        box = new Box();
    }

    //! After the marks are prepared
    function prepare(markReach as Number, markWidth as Number) as Void {
        dotRadius = Numbers.max(markWidth, MIN_RADIUS);
        ringWidth = Numbers.max(dotRadius / RING_DIVISOR, MIN_RING);
        orbitRadius = Dial.rim - markReach - RimPainter.penRadius(markWidth) - MARK_GAP - dotRadius;
    }

    function setColor(color as Number) as Void {
        self.color = color;
    }

    function draw(dc as Dc) as Void {
        var share = progress.share();

        if (share == null) {
            box.clear();
            return;
        }

        place(share);

        if (isVisible) {
            paint(dc);
        }
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (ClipRegion.covers(box)) {
            paint(dc);
        }
    }

    //! A box of its own at the 12 when not shown, so redraw() finds nothing
    function getBoundingBox() as Graphics.BoundingBox {
        var outline = box;

        if (outline.isEmpty()) {
            var radians = Dial.radiansOf(0);

            outline = new Box();
            surround(outline, Dial.pointX(radians, orbitRadius), Dial.pointY(radians, orbitRadius));
        }

        var boundingBox = new Graphics.BoundingBox();
        boundingBox.addRectangle(outline.left, outline.top, outline.width, outline.height);

        return boundingBox;
    }

    private function place(share as Float) as Void {
        var radians = Dial.radiansOf(share * Dial.DEGREES_PER_CIRCLE);

        dotX = Dial.pointX(radians, orbitRadius);
        dotY = Dial.pointY(radians, orbitRadius);
        isDone = (share >= 1.0);
        surround(box, dotX, dotY);
    }

    private function surround(outline as Box, x as Number, y as Number) as Void {
        var across = (2 * dotRadius) + 1;

        outline.aroundCenter(x, y, across, across);
    }

    private function paint(dc as Dc) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        if (isDone) {
            dc.fillCircle(dotX, dotY, dotRadius);
            return;
        }

        // The pen reaches half its width either side of the radius.
        dc.setPenWidth(ringWidth);
        dc.drawCircle(dotX, dotY, dotRadius - (ringWidth / 2));
    }
}
