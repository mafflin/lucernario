import Toybox.Graphics;
import Toybox.Lang;

//! The hour hand: a mark at the hour, twice as wide as an hour mark and a
//! third longer, in the rim's colors inverted - see DayColors - and the
//! accent color until the sun is known. Reaching past the marks, it is put
//! back when the seconds hand's clip cuts into it: a tick or two a minute.
class HourHand {

    private const WIDTH_FACTOR = 2;
    private const LENGTH_NUMERATOR = 4;
    private const LENGTH_DIVISOR = 3;

    private var dayColors as DayColors;

    //! Until the sun is known
    private var accentColor as Number = Graphics.COLOR_WHITE;
    private var drawnColor as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare()
    private var width as Number = 0;
    private var length as Number = 0;

    //! Where it was last drawn, its ends on the glass, and the box around them
    private var position as Float = 0.0;
    private var ends as Array<[Numeric, Numeric]>;
    private var box as Box;

    function initialize(dayColors as DayColors) {
        self.dayColors = dayColors;
        ends = [[0, 0], [0, 0]] as Array<[Numeric, Numeric]>;
        box = new Box();
    }

    //! After the marks are prepared
    function prepare(markReach as Number, markWidth as Number) as Void {
        width = markWidth * WIDTH_FACTOR;
        length = markReach * LENGTH_NUMERATOR / LENGTH_DIVISOR;
    }

    //! How far in from the rim the pen comes
    function reach() as Number {
        return length + RimPainter.penRadius(width);
    }

    function setColor(color as Number) as Void {
        accentColor = color;
    }

    //! After the day colors have refreshed
    function draw(dc as Dc) as Void {
        position = Dial.positionOfMinute(currentMinute());
        placeBox();

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
        RimPainter.setPen(dc, drawnColor, width);
        RimPainter.drawRadial(dc, position, length);
    }

    //! From the rim to the inner end; the overshoot off the glass cannot be
    //! cut into
    private function placeBox() as Void {
        var radians = Dial.radiansOf(position);
        var inner = Dial.rim - length;

        ends[0] = [Dial.pointX(radians, Dial.rim), Dial.pointY(radians, Dial.rim)];
        ends[1] = [Dial.pointX(radians, inner), Dial.pointY(radians, inner)];

        box.aroundPoints(ends, RimPainter.penRadius(width));
    }

    //! Minutes past midnight: the hand stands between the hour marks
    private function currentMinute() as Number {
        var time = Clock.now();

        return (time.hour * Clock.MINUTES_PER_HOUR) + time.min;
    }
}
