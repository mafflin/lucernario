import Toybox.Graphics;
import Toybox.Lang;

//! The numerals on the rim: the quarter hours of the day, at noon, three,
//! six and nine on the dial.
//!
//! In the smallest system font, sat right against the inner ends of their
//! marks, inside the ring the hand sweeps. The hand's clip reaches past the
//! ring by its padding, so a partial update passing one of the marks has to
//! put the numeral back too.
class RimNumerals {

    //! Air between the end of the mark and the digits. The mark is smoothed,
    //! so a pixel keeps its soft end off the glyphs at the top and the sides.
    //! The bottom wants more: the digits stand on the baseline, and where the
    //! font puts its baseline is measured by the ascent, which runs a little
    //! short of where the glyphs actually end.
    private const _TOP_GAP = 1;
    private const _SIDE_GAP = 5;
    private const _BOTTOM_GAP = 4;

    //! How far above the mark's centerline the side numerals sit. Centered
    //! on the ascent they read low, for the same reason the bottom wants its
    //! larger gap: the ascent runs past the top of the digits, so the middle
    //! of the ascent is below the middle of the glyphs.
    private const _SIDE_LIFT = 2;

    //! The font all of them are drawn in: the smallest of the system scale.
    //! The vector face goes smaller still, but not legibly.
    private const _FONT = Graphics.FONT_XTINY;

    //! Where the numerals sit, in order: top, right, bottom, left
    private const _QUARTERS = 4;
    private const _TOP = 0;
    private const _RIGHT = 1;
    private const _BOTTOM = 2;
    private const _LEFT = 3;

    //! The numeral at each quarter
    private var _texts as Array<String>;

    //! Where each numeral is anchored and how it hangs off the anchor,
    //! resolved in prepare(). The x is the justified edge, the y the top of
    //! the text box.
    private var _xs as Array<Number>;
    private var _ys as Array<Number>;
    private var _justify as Array<Number>;

    //! Each numeral's text box, for the clip test
    private var _lefts as Array<Number>;
    private var _widths as Array<Number>;
    private var _height as Number = 0;

    //! The color the numerals are drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Constructor
    function initialize() {
        var quarter = Dial.HOUR_MARKS / _QUARTERS;

        // Noon reads as the full count rather than zero.
        _texts = [
            Dial.HOUR_MARKS.toString(),
            quarter.toString(),
            (2 * quarter).toString(),
            (3 * quarter).toString()
        ];

        _justify = [
            Graphics.TEXT_JUSTIFY_CENTER,
            Graphics.TEXT_JUSTIFY_RIGHT,
            Graphics.TEXT_JUSTIFY_CENTER,
            Graphics.TEXT_JUSTIFY_LEFT
        ] as Array<Number>;

        _xs = new [_QUARTERS] as Array<Number>;
        _ys = new [_QUARTERS] as Array<Number>;
        _lefts = new [_QUARTERS] as Array<Number>;
        _widths = new [_QUARTERS] as Array<Number>;
    }

    //! Place the numerals against the marks. Run after Dial.setup().
    //! @param dc The drawing context
    //! @param markReach How far in from the rim the marks come
    function prepare(dc as Dc, markReach as Number) as Void {
        // The digits stand on the baseline and never reach below it, so the
        // ink runs from the top of the box to the ascent, not the full height.
        var ink = Fonts.inkHeightOf(dc, _FONT);
        var inner = Dial.rim - markReach;

        _height = dc.getFontHeight(_FONT);

        for (var i = 0; i < _QUARTERS; i++) {
            _widths[i] = dc.getTextWidthInPixels(_texts[i], _FONT);
        }

        // Top and bottom hang off the axis, the sides off the mark's end.
        _xs[_TOP] = Dial.centerX;
        _ys[_TOP] = Dial.centerY - inner + _TOP_GAP;

        _xs[_RIGHT] = Dial.centerX + inner - _SIDE_GAP;
        _ys[_RIGHT] = Dial.centerY - (ink / 2) - _SIDE_LIFT;

        _xs[_BOTTOM] = Dial.centerX;
        _ys[_BOTTOM] = Dial.centerY + inner - _BOTTOM_GAP - ink;

        _xs[_LEFT] = Dial.centerX - inner + _SIDE_GAP;
        _ys[_LEFT] = _ys[_RIGHT];

        _lefts[_TOP] = _xs[_TOP] - (_widths[_TOP] / 2);
        _lefts[_RIGHT] = _xs[_RIGHT] - _widths[_RIGHT];
        _lefts[_BOTTOM] = _xs[_BOTTOM] - (_widths[_BOTTOM] / 2);
        _lefts[_LEFT] = _xs[_LEFT];
    }

    //! Set the color the numerals are drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw every numeral
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        for (var i = 0; i < _QUARTERS; i++) {
            paint(dc, i);
        }
    }

    //! Put back whichever numerals the hand's clip has cut into, if any
    //! @param dc The drawing context
    function redraw(dc as Dc) as Void {
        for (var i = 0; i < _QUARTERS; i++) {
            if (ClipRegion.covers(_lefts[i], _ys[i], _widths[i], _height)) {
                paint(dc, i);
            }
        }
    }

    //! Draw one numeral
    //! @param dc The drawing context
    //! @param quarter Which one, counting clockwise from the top
    private function paint(dc as Dc, quarter as Number) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_xs[quarter], _ys[quarter], _FONT, _texts[quarter], _justify[quarter]);
    }
}
