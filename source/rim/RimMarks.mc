import Toybox.Graphics;
import Toybox.Lang;

//! The twenty four hour marks around the rim, midnight at the top, and four
//! minor marks between each pair, one every twelve minutes.
//!
//! Lifted from the electric watch face, with no setting of their own.
//!
//! Colored with the day, each mark by the moment it stands for - see
//! DayColors.
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

    //! Minor marks between each pair of hour marks, splitting the hour into
    //! twelve minute steps
    private const _MINOR_MARKS = 4;
    private const _MINOR_STEPS = _MINOR_MARKS + 1;

    //! How far in a minor mark reaches, as a share of an hour mark's reach
    private const _MINOR_LENGTH_NUMERATOR = 2;
    private const _MINOR_LENGTH_DIVISOR = 3;

    //! A minor mark is as thin as the pen draws
    private const _MINOR_WIDTH = 1;

    //! How far in a mark reaches, resolved in prepare()
    private var _length as Number = 0;

    //! How wide a mark is in pixels, resolved in prepare()
    private var _width as Number = _MIN_WIDTH;

    //! How far in a minor mark reaches, resolved in prepare()
    private var _minorLength as Number = 0;

    //! The colors of the day, shared with the numerals
    private var _dayColors as DayColors;

    //! Constructor
    //! @param dayColors The colors of the day
    function initialize(dayColors as DayColors) {
        _dayColors = dayColors;
    }

    //! Size the marks off the ring. Run after Dial.setup().
    function prepare() as Void {
        _length = Dial.ringDepth * _LENGTH_NUMERATOR / _LENGTH_DIVISOR;
        _width = Dial.rim * _WIDTH_NUMERATOR / _WIDTH_DIVISOR;

        if (_width < _MIN_WIDTH) {
            _width = _MIN_WIDTH;
        }

        _minorLength = _length * _MINOR_LENGTH_NUMERATOR / _MINOR_LENGTH_DIVISOR;
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

    //! Draw every mark
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        var minorStep = Dial.DEGREES_PER_HOUR_MARK.toFloat() / _MINOR_STEPS;

        for (var mark = 0; mark < Dial.HOUR_MARKS; mark++) {
            var hour = positionOf(mark);

            RimPainter.drawRadial(dc, hour, _dayColors.colorAt(hour), _width, _length);

            for (var step = 1; step < _MINOR_STEPS; step++) {
                var degrees = hour + (step * minorStep);
                RimPainter.drawRadial(dc, degrees, _dayColors.colorAt(degrees), _MINOR_WIDTH, _minorLength);
            }
        }
    }

    //! Where a mark sits on the dial
    //! @param mark Which mark, counting clockwise from midnight
    //! @return The position in degrees, clockwise from midnight
    private function positionOf(mark as Number) as Number {
        return mark * Dial.DEGREES_PER_HOUR_MARK;
    }
}
