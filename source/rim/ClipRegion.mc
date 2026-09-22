import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! What a partial update is allowed to touch: one box around the seconds
//! hand, and the test that tells the rim marks whether any of them fall
//! inside it. A partial update has a budget, and the cheapest draw is the one
//! never issued.
module ClipRegion {

    //! Absorbs what the corners of the box miss: arc bulge, truncation, pen
    //! ends. The bulge scales with the radius; the floor is what the small
    //! screens, the ones running partial updates, already had.
    const CLIP_PADDING_DIVISOR = 5;
    const MIN_CLIP_PADDING = 4;

    //! The box's own reach. It is a rectangle around the hand's arc, so how
    //! far it actually reaches varies with where it sits.
    const SLOP_DEGREES = 9;

    var padding as Number = MIN_CLIP_PADDING;

    //! The last box, so callers can test it without allocating
    var boxX as Number = 0;
    var boxY as Number = 0;
    var boxWidth as Number = 0;
    var boxHeight as Number = 0;
    var centerDegrees as Numeric = 0;

    //! Size the padding off the ring. Run after Dial.setup().
    function setup() as Void {
        padding = Dial.ringDepth / CLIP_PADDING_DIVISOR;

        if (padding < MIN_CLIP_PADDING) {
            padding = MIN_CLIP_PADDING;
        }
    }

    //! Restrict drawing to one hand position
    //! @param dc The drawing context
    //! @param valueDegrees Where the hand sits, clockwise from noon
    //! @param angularWidthDegrees How wide the hand is
    //! @param radialLength How far in from the rim it reaches
    function clip(dc as Dc, valueDegrees as Numeric, angularWidthDegrees as Numeric, radialLength as Number) as Void {
        var outer = Dial.rim;
        var inner = outer - radialLength;
        var half = angularWidthDegrees / 2.0;
        var from = Dial.radiansOf(valueDegrees + half);
        var to = Dial.radiansOf(valueDegrees - half);

        var fromX = Math.cos(from);
        var toX = Math.cos(to);

        // Screen y grows downward, so the sine of the angle is negated.
        var fromY = -Math.sin(from);
        var toY = -Math.sin(to);

        var x1 = (Dial.centerX + lowEdge(fromX, toX, inner, outer)).toNumber() - padding;
        var y1 = (Dial.centerY + lowEdge(fromY, toY, inner, outer)).toNumber() - padding;
        var x2 = (Dial.centerX + highEdge(fromX, toX, inner, outer)).toNumber() + padding;
        var y2 = (Dial.centerY + highEdge(fromY, toY, inner, outer)).toNumber() + padding;

        if (x1 < 0) { x1 = 0; }
        if (y1 < 0) { y1 = 0; }
        if (x2 > Dial.screenWidth) { x2 = Dial.screenWidth; }
        if (y2 > Dial.screenHeight) { y2 = Dial.screenHeight; }

        boxX = x1;
        boxY = y1;
        boxWidth = x2 - x1;
        boxHeight = y2 - y1;
        centerDegrees = valueDegrees;

        dc.setClip(boxX, boxY, boxWidth, boxHeight);
    }

    //! How far the arc reaches to the low side of one axis. Each end has a
    //! corner at both radii; a negative component flips which of the two sits
    //! on which side.
    //! @param from The component at one end of the arc
    //! @param to The component at the other end
    //! @param inner The inner radius of the shape
    //! @param outer The outer radius of the shape
    //! @return The reach in pixels, signed
    function lowEdge(from as Numeric, to as Numeric, inner as Number, outer as Number) as Numeric {
        var edge = (from < to) ? from : to;

        return edge * ((edge < 0) ? outer : inner);
    }

    //! How far the arc reaches to the high side of one axis
    //! @param from The component at one end of the arc
    //! @param to The component at the other end
    //! @param inner The inner radius of the shape
    //! @param outer The outer radius of the shape
    //! @return The reach in pixels, signed
    function highEdge(from as Numeric, to as Numeric, inner as Number, outer as Number) as Numeric {
        var edge = (from > to) ? from : to;

        return edge * ((edge < 0) ? inner : outer);
    }

    //! Can something at this angle land inside the last box? Cheaper than
    //! issuing a draw the clip throws away.
    //! @param valueDegrees Where the shape sits, clockwise from noon
    //! @param angularWidthDegrees How wide the shape is
    //! @return true when it may fall inside the box
    function reaches(valueDegrees as Numeric, angularWidthDegrees as Numeric) as Boolean {
        var gap = centerDegrees - valueDegrees;

        if (gap < 0) {
            gap = -gap;
        }

        if (gap > (Dial.DEGREES_PER_CIRCLE / 2)) {
            gap = Dial.DEGREES_PER_CIRCLE - gap;
        }

        return gap <= (SLOP_DEGREES + (angularWidthDegrees / 2.0));
    }

    //! Whether the last box overlaps the given rectangle. Lets anything drawn
    //! inside the rim ask once whether a partial update has cut into it.
    //! @param x The left edge
    //! @param y The top edge
    //! @param width The width
    //! @param height The height
    //! @return true when the two overlap
    function covers(x as Number, y as Number, width as Number, height as Number) as Boolean {
        return (x < (boxX + boxWidth))
            && ((x + width) > boxX)
            && (y < (boxY + boxHeight))
            && ((y + height) > boxY);
    }
}
