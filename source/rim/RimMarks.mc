import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The twenty four hour marks around the rim, midnight at the top.
//!
//! Lifted from the electric watch face, cut down to hour marks at the one
//! size. There is no setting of its own: the marks come and go with the style
//! that shows the seconds hand, which is what they are there to read against.
//!
//! Each mark stands for an hour of the day and is colored by where the sun is
//! then: amber through daylight, sky blue through the night. Until the sun is
//! known they take the face's data color.
//!
//! Two more marks, finer and shorter, stand at the minute the sun rises and
//! the minute it sets. The sunrise mark is in the day color and the sunset
//! mark in the night color: each points at what it brings.
class RimMarks {

    //! How wide a mark is, as a share of the rim radius rather than a fixed
    //! count, so it holds its proportions on every screen. Narrower than the
    //! hand that sweeps over them, which is what tells the two apart at a
    //! glance.
    //!
    //! Pixels, not degrees of arc: a mark is about a degree wide, and drawArc
    //! renders in whole degrees, so every width from one degree to two came
    //! out as the same mark. A quarter of a degree of movement is worth
    //! having on a shape this small. A fortieth of the radius is where the
    //! old one and a half degrees landed.
    private const _WIDTH_NUMERATOR = 1;
    private const _WIDTH_DIVISOR = 40;

    //! A mark thinner than this is not a mark
    private const _MIN_WIDTH = 1;

    //! How far in from the rim a mark reaches, as a share of the ring
    private const _LENGTH_NUMERATOR = 2;
    private const _LENGTH_DIVISOR = 5;

    //! The sun marks, finer and shorter than the hour marks they sit among
    private const _SUN_WIDTH_NUMERATOR = 1;
    private const _SUN_WIDTH_DIVISOR = 50;
    private const _SUN_LENGTH_NUMERATOR = 2;
    private const _SUN_LENGTH_DIVISOR = 5;

    //! The color the marks are drawn in when the sun is not known
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Where the sun is through the day. The view's, refreshed by it once per
    //! full update and shared with the hour hand.
    private var _daylight as Daylight;

    //! How far in a mark reaches, resolved in prepare()
    private var _length as Number = 0;

    //! How wide a mark is in pixels, resolved in prepare()
    private var _width as Number = _MIN_WIDTH;

    //! The same width as an angle: the arc a mark subtends at the rim. The
    //! clip test is the only thing that still wants the width in degrees.
    private var _widthDegrees as Float = 0.0;

    //! The sun marks' size, resolved in prepare() the same way
    private var _sunLength as Number = 0;
    private var _sunWidth as Number = _MIN_WIDTH;
    private var _sunWidthDegrees as Float = 0.0;

    //! Constructor
    //! @param daylight Where the sun is through the day
    function initialize(daylight as Daylight) {
        _daylight = daylight;
    }

    //! Size the marks off the ring. Run after Dial.setup().
    function prepare() as Void {
        _length = Dial.ringDepth * _LENGTH_NUMERATOR / _LENGTH_DIVISOR;
        _width = Dial.rim * _WIDTH_NUMERATOR / _WIDTH_DIVISOR;

        if (_width < _MIN_WIDTH) {
            _width = _MIN_WIDTH;
        }

        _widthDegrees = Math.toDegrees(_width.toFloat() / Dial.rim).toFloat();

        _sunLength = Dial.ringDepth * _SUN_LENGTH_NUMERATOR / _SUN_LENGTH_DIVISOR;
        _sunWidth = Dial.rim * _SUN_WIDTH_NUMERATOR / _SUN_WIDTH_DIVISOR;

        if (_sunWidth < _MIN_WIDTH) {
            _sunWidth = _MIN_WIDTH;
        }

        _sunWidthDegrees = Math.toDegrees(_sunWidth.toFloat() / Dial.rim).toFloat();
    }

    //! How far in from the rim a mark comes, for whatever sits against its end
    //! @return The reach in pixels
    function reach() as Number {
        return _length;
    }

    //! Set the color the marks are drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw every mark, with today's sun
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        for (var mark = 0; mark < Dial.HOUR_MARKS; mark++) {
            paint(dc, mark);
        }

        paintSun(dc, _daylight.sunrise(), Palette.AMBER);
        paintSun(dc, _daylight.sunset(), Palette.SKY);
    }

    //! Put back the marks the hand is passing, if it is passing any at all.
    //! Only the ones inside the clip are worth issuing a draw for.
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        for (var mark = 0; mark < Dial.HOUR_MARKS; mark++) {
            if (ClipRegion.reaches(positionOf(mark), _widthDegrees)) {
                paint(dc, mark);
            }
        }

        redrawSun(dc, _daylight.sunrise(), Palette.AMBER);
        redrawSun(dc, _daylight.sunset(), Palette.SKY);
    }

    //! Draw one mark
    //! @param dc The drawing context
    //! @param mark Which mark, counting clockwise from noon
    private function paint(dc as Dc, mark as Number) as Void {
        RimPainter.drawRadial(dc, positionOf(mark), colorOf(mark), _width, _length);
    }

    //! The color of one mark, by whether the sun is up at its hour. The mark
    //! at the top is midnight, so the mark's index is its hour.
    //! @param mark Which mark, counting clockwise from midnight
    //! @return The color to draw in
    private function colorOf(mark as Number) as Number {
        return _daylight.colorAt(mark * Clock.MINUTES_PER_HOUR, _color);
    }

    //! Draw one sun mark, if the sun is known
    //! @param dc The drawing context
    //! @param minutes When, as minutes past midnight, null if not known
    //! @param color The color to draw in
    private function paintSun(dc as Dc, minutes as Number?, color as Number) as Void {
        if (minutes == null) {
            return;
        }

        RimPainter.drawRadial(dc, Dial.positionOfMinute(minutes), color, _sunWidth, _sunLength);
    }

    //! Put one sun mark back, if the hand is passing it
    //! @param dc The drawing context
    //! @param minutes When, as minutes past midnight, null if not known
    //! @param color The color to draw in
    private function redrawSun(dc as Dc, minutes as Number?, color as Number) as Void {
        if (minutes == null) {
            return;
        }

        var position = Dial.positionOfMinute(minutes);

        if (ClipRegion.reaches(position, _sunWidthDegrees)) {
            RimPainter.drawRadial(dc, position, color, _sunWidth, _sunLength);
        }
    }

    //! Where a mark sits on the dial
    //! @param mark Which mark, counting clockwise from midnight
    //! @return The position in degrees, clockwise from midnight
    private function positionOf(mark as Number) as Number {
        return mark * Dial.DEGREES_PER_HOUR_MARK;
    }
}
