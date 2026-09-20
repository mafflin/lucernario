import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

//! Renders the seconds at the bottom of the screen, below the time.
//!
//! Geometry is worked out once in prepare() and cached, because draw() runs
//! once a second against the partial update power budget.
class SecondsDisplay {

    //! How seconds are padded
    private const _FIELD_FORMAT = "%02d";

    //! The widest the seconds can render. Digits are uniform width in the
    //! faces we use, so any two digits would do.
    private const _WIDEST_FIELD = "88";

    //! Height of the seconds font as a fraction of the screen height
    private const _HEIGHT_RATIO = 0.11;

    //! Gap left between the text and the bottom of the screen, as a fraction
    //! of the screen height
    private const _BOTTOM_MARGIN_RATIO = 0.04;

    //! Slack added around the text when clipping, so anti-aliased edges are
    //! not left behind between partial updates
    private const _CLIP_PADDING = 2;

    //! The font the seconds are drawn with, resolved in prepare()
    private var _font as FontType = Graphics.FONT_SMALL;

    //! The color the seconds are drawn in
    private var _color as Number = Graphics.COLOR_WHITE;

    //! Center of the text, resolved in prepare()
    private var _centerX as Number = 0;
    private var _centerY as Number = 0;

    //! Size of the region the text occupies, including clip padding
    private var _boxWidth as Number = 0;
    private var _boxHeight as Number = 0;

    //! Constructor
    function initialize() {
    }

    //! Resolve the font and geometry for this screen. Call once per layout.
    //! @param dc The drawing context
    function prepare(dc as Dc) as Void {
        _font = pickFont(dc);

        _boxWidth = dc.getTextWidthInPixels(_WIDEST_FIELD, _font) + (2 * _CLIP_PADDING);
        _boxHeight = dc.getFontHeight(_font) + (2 * _CLIP_PADDING);

        var height = dc.getHeight();
        var margin = height * _BOTTOM_MARGIN_RATIO;

        _centerX = dc.getWidth() / 2;
        _centerY = (height - margin - (_boxHeight / 2)).toNumber();
    }

    //! Set the color the seconds are drawn in
    //! @param color The color to use
    function setColor(color as Number) as Void {
        _color = color;
    }

    //! Draw the current seconds
    //! @param dc The drawing context
    function draw(dc as Dc) as Void {
        dc.setColor(_color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            _centerX,
            _centerY,
            _font,
            System.getClockTime().sec.format(_FIELD_FORMAT),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    //! The region the seconds occupy, as [x, y, width, height]. Used to clip
    //! partial updates to just this part of the screen.
    //! @return The bounding box of the seconds
    function bounds() as Array<Number> {
        return [
            _centerX - (_boxWidth / 2),
            _centerY - (_boxHeight / 2),
            _boxWidth,
            _boxHeight
        ];
    }

    //! A font sized as a fraction of the screen, so the seconds stay small
    //! next to the time on every device
    //! @param dc The drawing context
    //! @return The font to draw with
    private function pickFont(dc as Dc) as FontType {
        if (Graphics has :getVectorFont) {
            var size = (dc.getHeight() * _HEIGHT_RATIO).toNumber();
            var font = FontFitter.vectorFontOf(size);

            if (font != null) {
                return font;
            }
        }

        return Graphics.FONT_SMALL;
    }
}
