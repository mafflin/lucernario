import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The seconds hand: an equilateral arrow inside the marks, pointing out.
//! Set in far enough that its clip box never reaches the marks at any
//! angle - on the diagonals a base corner pokes out past the tip. Ticks in
//! low power mode through partial updates, repainting only what it vacates.
class SecondsHand {

    //! The base, in degrees at the ring's inner edge
    private const _WIDTH_DEGREES = 8;

    //! Air between the tip and the marks' pen ends: the box's diagonal
    //! reach, a pixel of smoothing, and one for the corners themselves
    private const _MARK_GAP = 5;

    private var _color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare()
    private var _tip as Number = 0;
    private var _baseRadius as Float = 0.0;
    private var _halfWidth as Float = 0.0;

    //! Where it was last drawn, null when off screen
    private var _second as Number? = null;

    //! Filled in place rather than made anew each tick
    private var _points as Array<[Numeric, Numeric]>;
    private var _box as Box;

    function initialize() {
        _points = [[0, 0], [0, 0], [0, 0]] as Array<[Numeric, Numeric]>;
        _box = new Box();
    }

    //! After Dial.setup()
    function prepare(markReach as Number, markWidth as Number) as Void {
        var width = 2 * (Dial.rim - Dial.ringDepth) * Math.sin(Math.toRadians(_WIDTH_DEGREES / 2.0));

        _tip = Dial.rim - markReach - RimPainter.penRadius(markWidth) - _MARK_GAP;
        _baseRadius = (_tip - (width * RimPainter.EQUILATERAL_HEIGHT)).toFloat();
        _halfWidth = (width / 2).toFloat();
        _second = null;
    }

    function baseWidth() as Float {
        return _halfWidth * 2;
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    //! So the next tick does not lift it off a screen since repainted
    function forget() as Void {
        _second = null;
    }

    function draw(dc as Dc) as Void {
        place(Clock.now().sec);
        paint(dc);
    }

    //! Repaint only what the arrow vacates: it is opaque where it lands
    function drawPartial(dc as Dc, restoreRim as Method(dc as Dc, second as Number) as Void) as Void {
        var second = Clock.now().sec;
        var previous = _second;

        if (second == previous) {
            return;
        }

        // Where it was: lift it off and put the rim back.
        if (previous != null) {
            ClipRegion.clip(dc, _box);
            restoreRim.invoke(dc, previous);
        }

        // Where it is going: the box only bounds the draw.
        place(second);
        ClipRegion.clip(dc, _box);
        paint(dc);

        dc.clearClip();
    }

    private function place(second as Number) as Void {
        var radians = Dial.radiansOf(second * Dial.DEGREES_PER_SECOND);
        var outX = Math.cos(radians);

        // Screen y grows downward.
        var outY = -Math.sin(radians);

        // Across is out turned a quarter.
        var acrossX = -outY * _halfWidth;
        var acrossY = outX * _halfWidth;
        var baseX = Dial.centerX + (_baseRadius * outX);
        var baseY = Dial.centerY + (_baseRadius * outY);

        // Truncated, not rounded: this runs every second, and half a pixel is
        // nothing on a smoothed shape.
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

        _box.aroundCorners(tipX, tipY, leftX, leftY, rightX, rightY);
        _second = second;
    }

    private function paint(dc as Dc) as Void {
        RimPainter.fill(dc, _points, _color);
    }
}
