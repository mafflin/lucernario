import Toybox.Graphics;
import Toybox.Lang;

//! The hour hand: a mark at the hour, twice as wide as an hour mark and a
//! third longer, in the accent color. Reaching past the marks, it is put
//! back when the seconds hand's clip cuts into it: a tick or two a minute.
class HourHand {

    private const _WIDTH_FACTOR = 2;
    private const _LENGTH_NUMERATOR = 4;
    private const _LENGTH_DIVISOR = 3;

    private var _color as Number = Graphics.COLOR_WHITE;

    //! Resolved in prepare()
    private var _width as Number = 0;
    private var _length as Number = 0;

    //! Where it was last drawn, and the box around it
    private var _position as Float = 0.0;
    private var _box as Box;

    function initialize() {
        _box = new Box();
    }

    //! After the marks are prepared
    function prepare(markReach as Number, markWidth as Number) as Void {
        _width = markWidth * _WIDTH_FACTOR;
        _length = markReach * _LENGTH_NUMERATOR / _LENGTH_DIVISOR;
    }

    function setColor(color as Number) as Void {
        _color = color;
    }

    function draw(dc as Dc) as Void {
        _position = Dial.positionOfMinute(currentMinute());
        boxAround(_position);
        paint(dc);
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (ClipRegion.covers(_box)) {
            paint(dc);
        }
    }

    private function paint(dc as Dc) as Void {
        RimPainter.drawRadial(dc, _position, _color, _width, _length);
    }

    //! From the rim to the inner end; the overshoot off the glass cannot be
    //! cut into
    private function boxAround(position as Float) as Void {
        var radians = Dial.radiansOf(position);

        _box.aroundLine(
            Dial.pointX(radians, Dial.rim),
            Dial.pointY(radians, Dial.rim),
            Dial.pointX(radians, Dial.rim - _length),
            Dial.pointY(radians, Dial.rim - _length),
            RimPainter.penRadius(_width)
        );
    }

    //! Minutes past midnight: the hand stands between the hour marks
    private function currentMinute() as Number {
        var time = Clock.now();

        return (time.hour * Clock.MINUTES_PER_HOUR) + time.min;
    }
}
