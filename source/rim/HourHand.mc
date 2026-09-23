import Toybox.Graphics;
import Toybox.Lang;

//! The hour hand: a mark on the 24 hour dial at the hour, twice as wide as
//! the hour marks and otherwise the same - running in from the rim as far
//! as they do, in the data color. Once round a day rather than twice, so it
//! moves a quarter of a degree a minute.
//!
//! It lies wholly within the day and night band, where the seconds hand's
//! clip never reaches, so a partial update never has it to put back.
class HourHand {

    //! How much wider than an hour mark it is
    private const _WIDTH_FACTOR = 2;

    //! The color the hand is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! How wide it is and how far in it reaches, resolved in prepare()
    private var _width as Number = 0;
    private var _length as Number = 0;

    //! Constructor
    function initialize() {
    }

    //! Size the hand off the marks. Run after the marks are prepared.
    //! @param markWidth How wide an hour mark is
    //! @param markReach How far in from the rim the marks come
    function prepare(markWidth as Number, markReach as Number) as Void {
        _width = markWidth * _WIDTH_FACTOR;
        _length = markReach;
    }

    //! Set the color the hand is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw the hand where it stands now
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        var position = Dial.positionOfMinute(currentMinute());

        RimPainter.drawRadial(dc, position, _color, _width, _length);
    }

    //! The moment the hand points at: the hour, carried on by however much
    //! of it has gone
    //! @return Minutes past midnight
    private function currentMinute() as Number {
        var time = Clock.now();

        return (time.hour * Clock.MINUTES_PER_HOUR) + time.min;
    }
}
