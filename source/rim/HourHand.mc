import Toybox.Graphics;
import Toybox.Lang;

//! The hour hand: a mark on the 24 hour dial at the hour, twice as wide as
//! the hour marks and a third longer, in the accent color. Once round a day
//! rather than twice, so it moves a quarter of a degree a minute.
//!
//! Reaching past the marks, it runs into the clip of a seconds hand passing
//! it, so a partial update puts it back when the clip has cut into it: a
//! tick or two a minute, one line each.
class HourHand {

    //! How much wider than an hour mark it is
    private const _WIDTH_FACTOR = 2;

    //! How much longer than an hour mark it is
    private const _LENGTH_NUMERATOR = 4;
    private const _LENGTH_DIVISOR = 3;

    //! Pixels past the line's own half width for its smoothed edges, on the
    //! box a partial update tests it against
    private const _BOX_PADDING = 1;

    //! The color the hand is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! How wide it is and how far in it reaches, resolved in prepare()
    private var _width as Number = 0;
    private var _length as Number = 0;

    //! Where the hand was last drawn, and the upright box around it, taken
    //! in draw() so a partial update can test and redraw it as it stands
    private var _position as Float = 0.0;
    private var _left as Number = 0;
    private var _top as Number = 0;
    private var _boxWidth as Number = 0;
    private var _boxHeight as Number = 0;

    //! Constructor
    function initialize() {
    }

    //! Size the hand off the marks. Run after the marks are prepared.
    //! @param markWidth How wide an hour mark is
    //! @param markReach How far in from the rim the marks come
    function prepare(markWidth as Number, markReach as Number) as Void {
        _width = markWidth * _WIDTH_FACTOR;
        _length = markReach * _LENGTH_NUMERATOR / _LENGTH_DIVISOR;
    }

    //! Set the color the hand is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw the hand where it stands now
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        _position = Dial.positionOfMinute(currentMinute());
        boxAround(_position);
        paint(dc);
    }

    //! Put the hand back if the clip of a partial update has cut into it
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        if (ClipRegion.covers(_left, _top, _boxWidth, _boxHeight)) {
            paint(dc);
        }
    }

    //! Draw the hand where it was last placed
    //! @param dc The drawing context
    private function paint(dc as Dc) as Void {
        RimPainter.drawRadial(dc, _position, _color, _width, _length);
    }

    //! The upright box around the hand: its two ends, and half its width
    //! either side for the pen
    //! @param position Where it points, clockwise from midnight
    private function boxAround(position as Float) as Void {
        var radians = Dial.radiansOf(position);
        var outerX = Dial.pointX(radians, Dial.rim);
        var outerY = Dial.pointY(radians, Dial.rim);
        var innerX = Dial.pointX(radians, Dial.rim - _length);
        var innerY = Dial.pointY(radians, Dial.rim - _length);
        var reach = (_width / 2) + _BOX_PADDING;
        var left = (outerX < innerX) ? outerX : innerX;
        var top = (outerY < innerY) ? outerY : innerY;
        var right = (outerX > innerX) ? outerX : innerX;
        var bottom = (outerY > innerY) ? outerY : innerY;

        _left = left - reach;
        _top = top - reach;
        _boxWidth = (right - left) + (2 * reach) + 1;
        _boxHeight = (bottom - top) + (2 * reach) + 1;
    }

    //! The moment the hand points at: the hour, carried on by however much
    //! of it has gone
    //! @return Minutes past midnight
    private function currentMinute() as Number {
        var time = Clock.now();

        return (time.hour * Clock.MINUTES_PER_HOUR) + time.min;
    }
}
