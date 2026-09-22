import Toybox.Graphics;
import Toybox.Lang;

//! The seconds hand sweeping the rim.
//!
//! Lifted from the electric watch face, cut down to the one size. It ticks in
//! low power mode through partial updates, repainting only the pixels it
//! vacates.
class SecondsHand {

    //! How wide the hand is. The widest anything on the ring is drawn.
    private const _WIDTH_DEGREES = 4;

    //! The color the hand is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! How far in from the rim the hand reaches. The whole ring.
    private var _length as Number = 0;

    //! Where the hand was last drawn, or null when it is not on screen
    private var _position as Numeric? = null;

    //! Constructor
    function initialize() {
    }

    //! Size the hand off the ring. Run after Dial.setup().
    function prepare() as Void {
        _length = Dial.ringDepth;
        _position = null;
    }

    //! Set the color the hand is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Forget where the hand was, so the next partial update does not try to
    //! lift it off a screen that has since been repainted
    function forget() as Void {
        _position = null;
    }

    //! Draw the hand where it stands now
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        _position = currentPosition();

        RimPainter.drawArc(dc, _position, _color, _WIDTH_DEGREES, _length);
    }

    //! Repaint just the pixels the hand vacates. Where it is going needs
    //! nothing put back: the hand is opaque and covers whatever it lands on.
    //! @param dc The drawing context
    //! @param restoreRim Puts the rim back under the old position, called
    //!        with that position already clipped
    function drawPartial(dc as Dc, restoreRim as Method(dc as Dc) as Void) as Void {
        var next = currentPosition();
        var previous = _position;

        if (next == previous) {
            return;
        }

        // Where it was: lift the hand off and put the rim back underneath.
        if (previous != null) {
            ClipRegion.clip(dc, previous, _WIDTH_DEGREES, _length);
            restoreRim.invoke(dc);
        }

        // Where it is going: the box bounds the draw and nothing more.
        ClipRegion.clip(dc, next, _WIDTH_DEGREES, _length);
        RimPainter.drawArc(dc, next, _color, _WIDTH_DEGREES, _length);

        dc.clearClip();

        _position = next;
    }

    //! Where the hand stands right now
    //! @return The position in degrees, clockwise from noon
    private function currentPosition() as Numeric {
        return Clock.now().sec * Dial.DEGREES_PER_SECOND;
    }
}
