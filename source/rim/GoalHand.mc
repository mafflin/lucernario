import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! A dot going round once to the goal, just inside the hour hand's reach
class GoalHand extends WatchUi.Drawable {

    //! Air between the dot and the hour hand
    private const HAND_GAP = 2;
    private const MIN_RADIUS = 2;

    private var progress as GoalProgress;
    private var enabled as Boolean = false;
    private var color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare(): the dot's size, and the circle its center runs on
    private var dotRadius as Number = MIN_RADIUS;
    private var orbitRadius as Number = 0;

    //! As last drawn; empty when not shown
    private var dotX as Number = 0;
    private var dotY as Number = 0;
    private var box as Box;

    function initialize(progress as GoalProgress) {
        Drawable.initialize({ :identifier => SlotId.GOAL });

        self.progress = progress;
        box = new Box();
    }

    //! After the marks and the hour hand are prepared
    function prepare(handReach as Number, markWidth as Number) as Void {
        dotRadius = (markWidth < MIN_RADIUS) ? MIN_RADIUS : markWidth;
        orbitRadius = Dial.rim - handReach - HAND_GAP - dotRadius;
    }

    function setEnabled(enabled as Boolean) as Void {
        self.enabled = enabled;
    }

    function isEnabled() as Boolean {
        return enabled;
    }

    function setColor(color as Number) as Void {
        self.color = color;
    }

    function draw(dc as Dc) as Void {
        var share = progress.share();

        if (!enabled || (share == null)) {
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

    //! A box of its own at the 24 when not shown, so redraw() finds nothing
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
        surround(box, dotX, dotY);
    }

    private function surround(outline as Box, x as Number, y as Number) as Void {
        var across = (2 * dotRadius) + 1;

        outline.aroundCenter(x, y, across, across);
    }

    private function paint(dc as Dc) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dotX, dotY, dotRadius);
    }
}
