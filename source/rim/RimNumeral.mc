import Toybox.Graphics;
import Toybox.Lang;

//! The numeral on the rim: 24, at midnight, the top of the dial.
//!
//! In the smallest system font, sat right against the inner end of its
//! mark, inside the ring the hand sweeps, and in the data color as the marks
//! are. The hand's clip reaches past the ring by its padding, so a partial
//! update passing the mark has to put the numeral back too.
class RimNumeral {

    //! Air between the end of the mark and the digits. The mark is smoothed,
    //! so a pixel keeps its soft end off the glyphs.
    private const _GAP = 1;

    //! The font it is drawn in: the smallest of the system scale. The vector
    //! face goes smaller still, but not legibly.
    private const _FONT = Graphics.FONT_XTINY;

    //! Midnight reads as the full count rather than zero
    private var _text as String;

    //! The text box, resolved in prepare(): the x is its center, for drawing,
    //! and its left edge, for the clip test
    private var _x as Number = 0;
    private var _left as Number = 0;
    private var _y as Number = 0;
    private var _width as Number = 0;
    private var _height as Number = 0;

    //! The color the numeral is drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Constructor
    function initialize() {
        _text = Dial.HOUR_MARKS.toString();
    }

    //! Place the numeral against the mark. Run after Dial.setup().
    //! @param dc The drawing context
    //! @param markReach How far in from the rim the marks come
    function prepare(dc as Dc, markReach as Number) as Void {
        _height = dc.getFontHeight(_FONT);
        _width = dc.getTextWidthInPixels(_text, _FONT);

        _x = Dial.centerX;
        _left = _x - (_width / 2);
        _y = Dial.centerY - Dial.rim + markReach + _GAP;
    }

    //! Set the color the numeral is drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw the numeral
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_x, _y, _FONT, _text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    //! Put the numeral back if the hand's clip has cut into it
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        if (ClipRegion.covers(_left, _y, _width, _height)) {
            draw(dc);
        }
    }
}
