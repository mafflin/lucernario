import Toybox.Graphics;
import Toybox.Lang;

//! Progress to the day's steps goal: a dot going round once from the 12, a
//! few pixels inside the hour marks, and back at the 12 once the goal is
//! done. A ring until then, solid once it is.
class GoalHand {

    //! Air between the dot and the hour marks' pen ends
    private const MARK_GAP = 4;
    private const MIN_RADIUS = 2;

    //! The ring's width, as a share of the dot's radius, at least MIN_RING
    private const RING_DIVISOR = 2;
    private const MIN_RING = 2;

    private var color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare(): the dot's size, and the circle its center runs on
    private var dotRadius as Number = MIN_RADIUS;
    private var ringWidth as Number = MIN_RING;
    private var orbitRadius as Number = 0;

    //! 0 to 1, null for none
    private var share as Float? = null;

    function initialize() {
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

    //! 0 to 1; null without a goal, which shows nothing
    function setShare(share as Float?) as Void {
        self.share = share;
    }

    function draw(dc as Dc) as Void {
        var done = share;

        if (done == null) {
            return;
        }

        var radians = Dial.radiansOf(done * Dial.DEGREES_PER_CIRCLE);
        var x = Dial.pointX(radians, orbitRadius);
        var y = Dial.pointY(radians, orbitRadius);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        if (done >= 1.0) {
            dc.fillCircle(x, y, dotRadius);
            return;
        }

        // The pen reaches half its width either side of the radius.
        dc.setPenWidth(ringWidth);
        dc.drawCircle(x, y, dotRadius - (ringWidth / 2));
    }
}
