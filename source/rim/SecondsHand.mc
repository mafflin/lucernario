import Toybox.Graphics;
import Toybox.Lang;

//! The seconds hand: a dot going round inside the day and night band.
//!
//! Set in far enough that the box a partial update clips to around it never
//! reaches the band, at any angle, so a tick has neither the band nor the
//! hour marks to put back - both lie wholly within it. The box is square, so
//! its corners reach furthest on the diagonals, by the root of two.
//!
//! It ticks in low power mode through partial updates, repainting only the
//! pixels it vacates.
class SecondsHand {

    //! How big the dot is, as a share of the ring
    private const _RADIUS_DIVISOR = 4;
    private const _MIN_RADIUS = 3;

    //! Air between the band and the furthest corner of the clip box: the
    //! band's smoothed inner edge spills about a pixel inward, and the
    //! corner's own pixel reaches up to one more
    private const _BAND_GAP = 2;

    //! The root of two, a little over, as a number rather than a call
    private const _DIAGONAL = 1.415;

    //! The color the dot is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! The dot's radius, and how far its center stands from the dial's,
    //! resolved in prepare()
    private var _radius as Number = _MIN_RADIUS;
    private var _orbit as Number = 0;

    //! Which second the dot was last drawn at and where, or null when it is
    //! not on screen. The center rather than the angle, so lifting it off
    //! takes no trig.
    private var _second as Number? = null;
    private var _x as Number = 0;
    private var _y as Number = 0;

    //! Constructor
    function initialize() {
    }

    //! Size the dot off the ring. Run after Dial.setup().
    //! @param bandReach How far in from the rim the day and night band comes
    function prepare(bandReach as Number) as Void {
        _radius = Dial.ringDepth / _RADIUS_DIVISOR;

        if (_radius < _MIN_RADIUS) {
            _radius = _MIN_RADIUS;
        }

        var corner = ((_radius + ClipRegion.PADDING) * _DIAGONAL).toNumber() + 1;

        _orbit = Dial.rim - bandReach - _BAND_GAP - corner;
        _second = null;
    }

    //! Set the color the dot is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Forget where the dot was, so the next partial update does not try to
    //! lift it off a screen that has since been repainted
    function forget() as Void {
        _second = null;
    }

    //! Draw the dot where it stands now
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        place(Clock.now().sec);
        paint(dc);
    }

    //! Repaint just the pixels the dot vacates. Where it is going needs
    //! nothing put back: the dot is opaque and covers whatever it lands on.
    //! @param dc The drawing context
    //! @param restoreRim Puts the rim back under the old position, called
    //!        with that position already clipped
    function drawPartial(dc as Dc, restoreRim as Method(dc as Dc) as Void) as Void {
        var second = Clock.now().sec;
        var previous = _second;

        if (second == previous) {
            return;
        }

        // Where it was: lift the dot off and put the rim back underneath.
        if (previous != null) {
            ClipRegion.clip(dc, _x, _y, _radius, previous * Dial.DEGREES_PER_SECOND);
            restoreRim.invoke(dc);
        }

        // Where it is going: the box bounds the draw and nothing more.
        place(second);
        ClipRegion.clip(dc, _x, _y, _radius, second * Dial.DEGREES_PER_SECOND);
        paint(dc);

        dc.clearClip();
    }

    //! Work out where the dot stands at a second
    //! @param second The second, 0 to 59
    private function place(second as Number) as Void {
        var radians = Dial.radiansOf(second * Dial.DEGREES_PER_SECOND);

        _second = second;
        _x = Dial.pointX(radians, _orbit);
        _y = Dial.pointY(radians, _orbit);
    }

    //! Draw the dot where it was last placed
    //! @param dc The drawing context
    private function paint(dc as Dc) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_x, _y, _radius);
    }
}
