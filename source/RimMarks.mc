import Toybox.Graphics;
import Toybox.Lang;

//! The twelve hour marks around the rim.
//!
//! Lifted from the electric watch face, cut down to hour marks at the one
//! size. There is no setting of its own: the marks come and go with the style
//! that shows the seconds hand, which is what they are there to read against.
class RimMarks {

    //! Marks around the dial, one an hour
    private const _MARKS = 12;

    //! A full circle is half a day round, so an hour is 30 degrees of it
    private const _DEGREES_PER_MARK = 30;

    //! How wide a mark is, in degrees of arc rather than pixels, so it holds
    //! its proportions on every screen. Narrower than the hand that sweeps
    //! over them, which is what tells the two apart at a glance.
    private const _WIDTH_DEGREES = 1.5;

    //! How far in from the rim a mark reaches, as a share of the ring
    private const _LENGTH_NUMERATOR = 3;
    private const _LENGTH_DIVISOR = 4;

    //! The color the marks are drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! How far in a mark reaches, resolved in prepare()
    private var _length as Number = 0;

    //! Constructor
    function initialize() {
    }

    //! Size the marks off the ring. Run after Dial.setup().
    function prepare() as Void {
        _length = Dial.ringDepth * _LENGTH_NUMERATOR / _LENGTH_DIVISOR;
    }

    //! Set the color the marks are drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw every mark
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        for (var mark = 0; mark < _MARKS; mark++) {
            paint(dc, mark);
        }
    }

    //! Put back the marks the hand is passing, if it is passing any at all.
    //! Only the ones inside the clip are worth issuing a draw for.
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        for (var mark = 0; mark < _MARKS; mark++) {
            if (ClipRegion.reaches(mark * _DEGREES_PER_MARK, _WIDTH_DEGREES)) {
                paint(dc, mark);
            }
        }
    }

    //! Draw one mark
    //! @param dc The drawing context
    //! @param mark Which mark, counting clockwise from noon
    private function paint(dc as Dc, mark as Number) as Void {
        HandDrawer.draw(dc, mark * _DEGREES_PER_MARK, _color, _WIDTH_DEGREES, _length);
    }
}
