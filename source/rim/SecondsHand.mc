import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The seconds hand: an arrow inside the marks, pointing out at
//! the second - equilateral, with a base of eight degrees measured at the
//! ring's inner edge.
//!
//! Set in far enough that the box a partial update clips to around it never
//! reaches the marks, at any angle, so a tick has none of them to put back.
//! The box is the upright rectangle round the three corners, and on the
//! diagonals a base corner pokes out past the tip, which is what holds the
//! tip a few pixels off the marks. The hour hand reaches past them, and is
//! put back when the box cuts into it.
//!
//! It ticks in low power mode through partial updates, repainting only the
//! pixels it vacates.
class SecondsHand {

    //! The span of the base, measured at the ring's inner edge. Equilateral,
    //! so this is the whole of its size.
    private const _WIDTH_DEGREES = 8;

    //! Half the square root of three: an equilateral triangle's height over
    //! its base
    private const _EQUILATERAL_HEIGHT = 0.866;

    //! Air between the tip and the marks' ends: what the clip box reaches
    //! past the tip on the diagonals, the ends' smoothed edges spilling about
    //! a pixel inward, and one more for the corners' own pixels. Counted from
    //! where the pen stops, which is half its width past where a line ends.
    private const _MARK_GAP = 5;

    //! The color the arrow is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! How far out the tip and the base stand, and half the base, resolved in
    //! prepare()
    private var _tip as Number = 0;
    private var _base as Float = 0.0;
    private var _halfBase as Float = 0.0;

    //! Which second the arrow was last drawn at, or null when it is not on
    //! screen
    private var _second as Number? = null;

    //! The corners it was last drawn with, filled in place rather than made
    //! anew each tick, and the box around them
    private var _points as Array<[Numeric, Numeric]>;
    private var _left as Number = 0;
    private var _top as Number = 0;
    private var _right as Number = 0;
    private var _bottom as Number = 0;

    //! Constructor
    function initialize() {
        _points = [[0, 0], [0, 0], [0, 0]] as Array<[Numeric, Numeric]>;
    }

    //! Size the arrow off the ring. Run after Dial.setup().
    //! @param markReach How far in from the rim the marks come
    //! @param markWidth How wide an hour mark is
    function prepare(markReach as Number, markWidth as Number) as Void {
        var base = 2 * (Dial.rim - Dial.ringDepth) * Math.sin(Math.toRadians(_WIDTH_DEGREES / 2.0));

        // The pen is round and runs past the line's end by half its width.
        var penRadius = (markWidth + 1) / 2;

        _tip = Dial.rim - markReach - penRadius - _MARK_GAP;
        _base = (_tip - (base * _EQUILATERAL_HEIGHT)).toFloat();
        _halfBase = (base / 2).toFloat();
        _second = null;
    }

    //! How wide the base is, for whatever is sized to match
    //! @return The width in pixels
    function baseWidth() as Float {
        return _halfBase * 2;
    }

    //! Set the color the arrow is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Forget where the arrow was, so the next partial update does not try to
    //! lift it off a screen that has since been repainted
    function forget() as Void {
        _second = null;
    }

    //! Draw the arrow where it stands now
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        place(Clock.now().sec);
        paint(dc);
    }

    //! Repaint just the pixels the arrow vacates. Where it is going needs
    //! nothing put back: the arrow is opaque and covers whatever it lands on.
    //! @param dc The drawing context
    //! @param restoreRim Puts the rim back under the old position, called
    //!        with that position already clipped and the second it was at
    function drawPartial(dc as Dc, restoreRim as Method(dc as Dc, second as Number) as Void) as Void {
        var second = Clock.now().sec;
        var previous = _second;

        if (second == previous) {
            return;
        }

        // Where it was: lift the arrow off and put the rim back underneath.
        if (previous != null) {
            ClipRegion.clip(dc, _left, _top, _right, _bottom);
            restoreRim.invoke(dc, previous);
        }

        // Where it is going: the box bounds the draw and nothing more.
        place(second);
        ClipRegion.clip(dc, _left, _top, _right, _bottom);
        paint(dc);

        dc.clearClip();
    }

    //! Work out the corners at a second, and the box around them
    //! @param second The second, 0 to 59
    private function place(second as Number) as Void {
        var radians = Dial.radiansOf(second * Dial.DEGREES_PER_SECOND);
        var outX = Math.cos(radians);

        // Screen y grows downward, so the sine of the angle is negated.
        var outY = -Math.sin(radians);

        // Across the arrow is out turned a quarter: (-outY, outX).
        var acrossX = -outY * _halfBase;
        var acrossY = outX * _halfBase;
        var baseX = Dial.centerX + (_base * outX);
        var baseY = Dial.centerY + (_base * outY);

        var tipX = (Dial.centerX + (_tip * outX)).toNumber();
        var tipY = (Dial.centerY + (_tip * outY)).toNumber();
        var leftX = (baseX + acrossX).toNumber();
        var leftY = (baseY + acrossY).toNumber();
        var rightX = (baseX - acrossX).toNumber();
        var rightY = (baseY - acrossY).toNumber();

        var tip = _points[0];
        var left = _points[1];
        var right = _points[2];

        tip[0] = tipX;
        tip[1] = tipY;
        left[0] = leftX;
        left[1] = leftY;
        right[0] = rightX;
        right[1] = rightY;

        _left = min3(tipX, leftX, rightX);
        _right = max3(tipX, leftX, rightX);
        _top = min3(tipY, leftY, rightY);
        _bottom = max3(tipY, leftY, rightY);
        _second = second;
    }

    //! Fill the arrow at its last corners
    //! @param dc The drawing context
    private function paint(dc as Dc) as Void {
        RimPainter.fill(dc, _points, _color);
    }

    //! The least of three
    //! @param a The first
    //! @param b The second
    //! @param c The third
    //! @return The least
    private function min3(a as Number, b as Number, c as Number) as Number {
        var least = (a < b) ? a : b;

        return (least < c) ? least : c;
    }

    //! The greatest of three
    //! @param a The first
    //! @param b The second
    //! @param c The third
    //! @return The greatest
    private function max3(a as Number, b as Number, c as Number) as Number {
        var most = (a > b) ? a : b;

        return (most > c) ? most : c;
    }
}
