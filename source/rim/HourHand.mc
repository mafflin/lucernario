import Toybox.Graphics;
import Toybox.Lang;

//! The hour hand: an arrow standing on the inner edge of the ring, pointing
//! out at the hour on the 24 hour dial.
//!
//! Lifted from the electric watch face, without its setting to turn it on and
//! its own color: it is always on here, and it is colored as the hour marks
//! are, by whether the sun is up at the moment it points at. Once round a day
//! rather than twice, so it moves a quarter of a degree a minute.
class HourHand {

    //! The span at its base. Equilateral, so this is the whole of its size: a
    //! wider hand is a longer one.
    private const _WIDTH_DEGREES = 7;

    //! The color the hand is drawn in when the sun is not known
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Where the sun is through the day. The view's, shared with the marks.
    private var _daylight as Daylight;

    //! The color the hand was last drawn in, so the tick refills it the same
    private var _drawnColor as Number = Graphics.COLOR_WHITE;

    //! Where the hand stood at the last full draw, and the corners it was
    //! drawn with. Null when it is not on screen.
    private var _position as Float? = null;
    private var _points as Array<[Numeric, Numeric]>? = null;

    //! Constructor
    //! @param daylight Where the sun is through the day
    function initialize(daylight as Daylight) {
        _daylight = daylight;
    }

    //! Set the color the hand is drawn in until the sun is known
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw the hand where it stands now
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        var minutes = currentMinute();
        var position = Dial.positionOfMinute(minutes);
        var points = RimPainter.arrowPoints(position, _WIDTH_DEGREES);

        _position = position;
        _points = points;
        _drawnColor = _daylight.colorAt(minutes, _color);

        RimPainter.fill(dc, points, _drawnColor);
    }

    //! Put the hand back where the seconds hand has cut into it. From the
    //! last full draw: the hand moves a quarter of a degree a minute, so the
    //! corners it was drawn at still stand and the tick only fills them.
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        var position = _position;
        var points = _points;

        if ((position == null) || (points == null)) {
            return;
        }

        if (!ClipRegion.reaches(position, _WIDTH_DEGREES)) {
            return;
        }

        RimPainter.fill(dc, points, _drawnColor);
    }

    //! The moment the hand points at: the hour, carried on by however much
    //! of it has gone
    //! @return Minutes past midnight
    private function currentMinute() as Number {
        var time = Clock.now();

        return (time.hour * Clock.MINUTES_PER_HOUR) + time.min;
    }
}
