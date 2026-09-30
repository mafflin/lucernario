import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The hour hand: a rhombus, the seconds hand's arrow made narrower and
//! mirrored inward across its base, the outer tip on the minor marks' tips. In the rim's colors inverted - see DayColors - and the accent color
//! until the sun is known. The seconds hand passes over it, so it is put back
//! when that clip cuts into it.
class HourHand {

    //! Across the middle, in degrees at the ring's inner edge
    private const WIDTH_DEGREES = 5;

    //! Round the outline, so the polygon does not cross itself
    private const OUTER_TIP = 0;
    private const LEFT = 1;
    private const INNER_TIP = 2;
    private const RIGHT = 3;

    private var dayColors as DayColors;

    //! Until the sun is known
    private var accentColor as Number = Graphics.COLOR_WHITE;
    private var drawnColor as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare()
    private var tipRadius as Number = 0;
    private var middleRadius as Float = 0.0;
    private var innerTipRadius as Float = 0.0;
    private var halfWidth as Float = 0.0;

    //! Where it was last drawn, and the box around it
    private var position as Float = 0.0;
    private var corners as Array<[Numeric, Numeric]>;
    private var box as Box;

    function initialize(dayColors as DayColors) {
        self.dayColors = dayColors;
        corners = [[0, 0], [0, 0], [0, 0], [0, 0]] as Array<[Numeric, Numeric]>;
        box = new Box();
    }

    //! After the marks are prepared
    function prepare(minorReach as Number) as Void {
        var fullWidth = RimPainter.widthAcross(WIDTH_DEGREES);
        var halfLength = fullWidth * RimPainter.EQUILATERAL_HEIGHT;

        tipRadius = Dial.rim - minorReach;
        middleRadius = tipRadius - halfLength;
        innerTipRadius = tipRadius - (2 * halfLength);
        halfWidth = fullWidth / 2;
    }

    function setColor(color as Number) as Void {
        accentColor = color;
    }

    //! After the day colors have refreshed
    function draw(dc as Dc) as Void {
        position = Dial.positionOfMinute(currentMinute());
        place();

        var inverted = dayColors.invertedColorAt(position);
        drawnColor = accentColor;

        if (inverted != null) {
            drawnColor = inverted;
        }

        paint(dc);
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (ClipRegion.covers(box)) {
            paint(dc);
        }
    }

    private function paint(dc as Dc) as Void {
        RimPainter.fill(dc, corners, drawnColor);
    }

    private function place() as Void {
        var radians = Dial.radiansOf(position);
        var outX = Math.cos(radians);

        // Screen y grows downward.
        var outY = -Math.sin(radians);

        // Across is out turned a quarter.
        var acrossX = -outY * halfWidth;
        var acrossY = outX * halfWidth;
        var middleX = Dial.centerX + (middleRadius * outX);
        var middleY = Dial.centerY + (middleRadius * outY);

        setCorner(OUTER_TIP, Dial.centerX + (tipRadius * outX), Dial.centerY + (tipRadius * outY));
        setCorner(LEFT, middleX + acrossX, middleY + acrossY);
        setCorner(INNER_TIP, Dial.centerX + (innerTipRadius * outX), Dial.centerY + (innerTipRadius * outY));
        setCorner(RIGHT, middleX - acrossX, middleY - acrossY);

        box.aroundPoints(corners, 0);
    }

    private function setCorner(index as Number, x as Decimal, y as Decimal) as Void {
        var corner = corners[index];

        corner[0] = Dial.pixel(x);
        corner[1] = Dial.pixel(y);
    }

    //! Minutes past midnight: the hand stands between the hour marks
    private function currentMinute() as Number {
        var time = Clock.now();

        return (time.hour * Clock.MINUTES_PER_HOUR) + time.min;
    }
}
