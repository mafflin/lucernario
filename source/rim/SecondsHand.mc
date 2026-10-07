import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The seconds hand: an equilateral arrow inside the marks, pointing out.
//! Set in far enough that its clip box never reaches the marks at any
//! angle - on the diagonals a base corner pokes out past the tip. Ticks in
//! low power mode through partial updates, repainting only what it vacates.
class SecondsHand {

    //! The base, in degrees at the ring's inner edge
    private const WIDTH_DEGREES = 8;

    //! Air between the tip and the marks' pen ends: the box's diagonal
    //! reach and a pixel of smoothing
    private const MARK_GAP = 3;

    private const TIP = 0;
    private const LEFT = 1;
    private const RIGHT = 2;

    private var color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare()
    private var tipRadius as Number = 0;
    private var baseRadius as Float = 0.0;
    private var halfWidth as Float = 0.0;

    //! Where it was last drawn, null when off screen
    private var drawnSecond as Number? = null;

    //! Filled in place rather than made anew each tick
    private var corners as Array<[Numeric, Numeric]>;
    private var box as Box;

    function initialize() {
        corners = [[0, 0], [0, 0], [0, 0]] as Array<[Numeric, Numeric]>;
        box = new Box();
    }

    //! After Dial.setup()
    function prepare(markReach as Number, markWidth as Number) as Void {
        var fullWidth = RimPainter.widthAcross(WIDTH_DEGREES);

        tipRadius = Dial.rim - markReach - RimPainter.penRadius(markWidth) - MARK_GAP;
        baseRadius = tipRadius - (fullWidth * RimPainter.EQUILATERAL_HEIGHT);
        halfWidth = fullWidth / 2;
        drawnSecond = null;
    }

    function baseWidth() as Float {
        return halfWidth * 2;
    }

    function setColor(color as Number) as Void {
        self.color = color;
    }

    //! So the next tick does not lift it off a screen since repainted
    function forget() as Void {
        drawnSecond = null;
    }

    function draw(dc as Dc) as Void {
        place(Clock.now().sec);
        paint(dc);
    }

    //! Repaint only what the arrow vacates: it is opaque where it lands
    function drawPartial(dc as Dc, restoreRim as Method(dc as Dc, second as Number) as Void) as Void {
        var second = Clock.now().sec;
        var previous = drawnSecond;

        if (second == previous) {
            return;
        }

        // Where it was: lift it off and put the rim back.
        if (previous != null) {
            ClipRegion.clip(dc, box);
            restoreRim.invoke(dc, previous);
        }

        // Where it is going: the box only bounds the draw.
        place(second);
        ClipRegion.clip(dc, box);
        paint(dc);

        dc.clearClip();
    }

    private function place(second as Number) as Void {
        var radians = Dial.radiansOf(second * Dial.DEGREES_PER_SECOND);
        var outX = Math.cos(radians);

        // Screen y grows downward.
        var outY = -Math.sin(radians);

        // Across is out turned a quarter.
        var acrossX = -outY * halfWidth;
        var acrossY = outX * halfWidth;
        var baseX = Dial.centerX + (baseRadius * outX);
        var baseY = Dial.centerY + (baseRadius * outY);

        setCorner(TIP, Dial.centerX + (tipRadius * outX), Dial.centerY + (tipRadius * outY));
        setCorner(LEFT, baseX + acrossX, baseY + acrossY);
        setCorner(RIGHT, baseX - acrossX, baseY - acrossY);

        box.aroundPoints(corners);
        drawnSecond = second;
    }

    //! Truncated, not rounded: this runs every second, and half a pixel is
    //! nothing on a smoothed shape
    private function setCorner(index as Number, x as Numeric, y as Numeric) as Void {
        var corner = corners[index];

        corner[0] = x.toNumber();
        corner[1] = y.toNumber();
    }

    private function paint(dc as Dc) as Void {
        RimPainter.fill(dc, corners, color);
    }
}
