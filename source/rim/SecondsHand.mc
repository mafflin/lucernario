import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The seconds hand: an equilateral arrow inside the marks, pointing out,
//! over the off screen face. Every second's corners and box are worked out
//! once per screen, so a tick only looks them up. In low power mode a
//! partial update copies the face back over the old box and the new one,
//! then draws.
class SecondsHand {

    private const COUNT = Dial.SECONDS_PER_TURN;

    //! The base, in degrees at the ring's inner edge
    private const WIDTH_DEGREES = 8;

    //! Air between the tip and the marks' pen ends
    private const MARK_GAP = 3;

    //! Past the arrow on every side, for the smoothed edges
    private const PADDING = 1;

    private var color as Number = Graphics.COLOR_WHITE;

    //! Per second: the tip and the two base corners, and the box they fit
    //! in, left, top, right and bottom
    private var corners as Array<Array<[Numeric, Numeric]> >;
    private var boxes as Array<Array<Number> >;

    //! Where it was last drawn, null when off screen
    private var drawnSecond as Number? = null;

    function initialize() {
        corners = new [COUNT] as Array<Array<[Numeric, Numeric]> >;
        boxes = new [COUNT] as Array<Array<Number> >;
    }

    //! After Dial.setup()
    function prepare(markReach as Number, markWidth as Number) as Void {
        var fullWidth = RimPainter.widthAcross(WIDTH_DEGREES);
        var tipRadius = Dial.rim - markReach - RimPainter.penRadius(markWidth) - MARK_GAP;
        var baseRadius = tipRadius - (fullWidth * RimPainter.EQUILATERAL_HEIGHT);

        for (var second = 0; second < COUNT; second++) {
            placeAt(second, tipRadius, baseRadius, fullWidth / 2);
        }

        forget();
    }

    function setColor(color as Number) as Void {
        self.color = color;
    }

    //! So the next tick does not lift it off a screen since repainted
    function forget() as Void {
        drawnSecond = null;
    }

    function draw(dc as Dc) as Void {
        paint(dc, Clock.now().sec);
    }

    //! Copy the face back over where it was and where it goes, then draw
    function drawPartial(dc as Dc, face as BufferedBitmap) as Void {
        var second = Clock.now().sec;
        var previous = drawnSecond;

        if (second == previous) {
            return;
        }

        if (previous == null) {
            previous = second;
        }

        clipAround(dc, previous, second);
        dc.drawBitmap(0, 0, face);
        paint(dc, second);
        dc.clearClip();
    }

    private function placeAt(second as Number, tipRadius as Number, baseRadius as Float, halfWidth as Float) as Void {
        var radians = Dial.radiansOf(second * Dial.DEGREES_PER_SECOND);
        var outX = Math.cos(radians);

        // Screen y grows downward.
        var outY = -Math.sin(radians);

        // Across is out turned a quarter.
        var acrossX = -outY * halfWidth;
        var acrossY = outX * halfWidth;
        var baseX = Dial.centerX + (baseRadius * outX);
        var baseY = Dial.centerY + (baseRadius * outY);

        var points = [
            [Dial.pixel(Dial.centerX + (tipRadius * outX)), Dial.pixel(Dial.centerY + (tipRadius * outY))],
            [Dial.pixel(baseX + acrossX), Dial.pixel(baseY + acrossY)],
            [Dial.pixel(baseX - acrossX), Dial.pixel(baseY - acrossY)]
        ] as Array<[Numeric, Numeric]>;

        corners[second] = points;
        boxes[second] = boxAround(points);
    }

    private function paint(dc as Dc, second as Number) as Void {
        RimPainter.fill(dc, corners[second], color);
        drawnSecond = second;
    }

    //! The box around both seconds
    private function clipAround(dc as Dc, first as Number, second as Number) as Void {
        var a = boxes[first];
        var b = boxes[second];
        var left = Numbers.min(a[0], b[0]);
        var top = Numbers.min(a[1], b[1]);
        var right = Numbers.max(a[2], b[2]);
        var bottom = Numbers.max(a[3], b[3]);

        dc.setClip(left, top, right - left, bottom - top);
    }

    //! The corners grown by PADDING, cut down to the screen; the far pixel
    //! is inside
    private function boxAround(points as Array<[Numeric, Numeric]>) as Array<Number> {
        var left = points[0][0] as Number;
        var top = points[0][1] as Number;
        var right = left;
        var bottom = top;

        for (var i = 1; i < points.size(); i++) {
            var x = points[i][0] as Number;
            var y = points[i][1] as Number;

            left = Numbers.min(left, x);
            top = Numbers.min(top, y);
            right = Numbers.max(right, x);
            bottom = Numbers.max(bottom, y);
        }

        return [
            Numbers.max(left - PADDING, 0),
            Numbers.max(top - PADDING, 0),
            Numbers.min(right + PADDING + 1, Dial.screenWidth),
            Numbers.min(bottom + PADDING + 1, Dial.screenHeight)
        ];
    }
}
