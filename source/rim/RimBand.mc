import Toybox.Graphics;
import Toybox.Lang;

//! The rim filled with the day: amber from the minute the sun rises to the
//! minute it sets, sky blue the rest of the way round. As deep as the hour
//! marks drawn over it. The seconds hand keeps clear of it, so a partial
//! update never has it to put back. Until the sun is known the rim is left
//! bare.
class RimBand {

    private const _DAY_COLOR = Palette.AMBER;
    private const _NIGHT_COLOR = Palette.DARK_SKY;

    //! Where the sun is through the day. The view's, refreshed by it once per
    //! full update.
    private var _daylight as Daylight;

    //! How far in from the rim the band reaches, resolved in prepare()
    private var _length as Number = 0;

    //! Constructor
    //! @param daylight Where the sun is through the day
    function initialize(daylight as Daylight) {
        _daylight = daylight;
    }

    //! Size the band to the marks. Run after Dial.setup().
    //! @param markReach How far in from the rim the marks come
    function prepare(markReach as Number) as Void {
        _length = markReach;
    }

    //! Fill the rim with today's day and night
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        var sunrise = _daylight.sunrise();
        var sunset = _daylight.sunset();

        if ((sunrise == null) || (sunset == null)) {
            return;
        }

        var rise = Dial.positionOfMinute(sunrise);
        var set = Dial.positionOfMinute(sunset);

        RimPainter.drawBand(dc, rise, set, _DAY_COLOR, _length);
        RimPainter.drawBand(dc, set, rise, _NIGHT_COLOR, _length);
    }
}
