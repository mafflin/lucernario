import Toybox.Graphics;
import Toybox.Lang;

//! The twenty four hour marks around the rim, midnight at the top.
//!
//! Lifted from the electric watch face, cut down to hour marks at the one
//! size, with no setting of their own.
//!
//! Drawn in the face's data color, on top of the day and night band.
class RimMarks {

    //! How wide a mark is, as a share of the rim radius rather than a fixed
    //! count, so it holds its proportions on every screen.
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

    //! The color the marks are drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! How far in a mark reaches, resolved in prepare()
    private var _length as Number = 0;

    //! How wide a mark is in pixels, resolved in prepare()
    private var _width as Number = _MIN_WIDTH;

    //! Constructor
    function initialize() {
    }

    //! Size the marks off the ring. Run after Dial.setup().
    function prepare() as Void {
        _length = Dial.ringDepth * _LENGTH_NUMERATOR / _LENGTH_DIVISOR;
        _width = Dial.rim * _WIDTH_NUMERATOR / _WIDTH_DIVISOR;

        if (_width < _MIN_WIDTH) {
            _width = _MIN_WIDTH;
        }
    }

    //! How far in from the rim a mark comes, for whatever sits against its end
    //! @return The reach in pixels
    function reach() as Number {
        return _length;
    }

    //! How wide a mark is, for whatever is sized to match
    //! @return The width in pixels
    function width() as Number {
        return _width;
    }

    //! Set the color the marks are drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw every mark
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        for (var mark = 0; mark < Dial.HOUR_MARKS; mark++) {
            paint(dc, mark);
        }
    }

    //! Draw one mark
    //! @param dc The drawing context
    //! @param mark Which mark, counting clockwise from noon
    private function paint(dc as Dc, mark as Number) as Void {
        RimPainter.drawRadial(dc, positionOf(mark), _color, _width, _length);
    }

    //! Where a mark sits on the dial
    //! @param mark Which mark, counting clockwise from midnight
    //! @return The position in degrees, clockwise from midnight
    private function positionOf(mark as Number) as Number {
        return mark * Dial.DEGREES_PER_HOUR_MARK;
    }
}
