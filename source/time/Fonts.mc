import Toybox.Graphics;
import Toybox.Lang;

//! What the face needs to know about a font that the dc does not say outright.
module Fonts {

    //! How tall the drawn glyphs actually are.
    //!
    //! Digits stand on the baseline and never reach below it, so the descent
    //! the font reserves is empty space. Anything placed against the digits
    //! would sit needlessly far off if it allowed for it.
    //! @param dc The drawing context
    //! @param font The font to measure
    //! @return The height of the glyphs in pixels
    function inkHeightOf(dc as Dc, font as FontType) as Number {
        if (Graphics has :getFontAscent) {
            return Graphics.getFontAscent(font);
        }

        return dc.getFontHeight(font);
    }
}
