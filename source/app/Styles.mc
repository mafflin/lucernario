import Toybox.Graphics;
import Toybox.Lang;

//! The style variations offered by the native watch face editor.
//!
//! The editor has no background setting, so the style id is what carries it:
//! a style is a way round for the colors. These ids must match the <style>
//! ids in resources/configs/watchface.xml.
module Styles {
    enum Value {
        DARK = 1,
        LIGHT = 2
    }

    //! The style used when the editor has not set one
    const DEFAULT = DARK;

    //! The background the style is drawn on
    //! @param style The selected style
    //! @return The background color
    function backgroundOf(style as Number) as Number {
        return isLight(style) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
    }

    //! The color to draw with when the editor has not chosen one: whatever
    //! reads against the background this style picked
    //! @param style The selected style
    //! @return The default foreground color
    function foregroundOf(style as Number) as Number {
        return isLight(style) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
    }

    //! Whether this style is dark on a light background rather than the other
    //! way round
    //! @param style The selected style
    //! @return true for the light style
    function isLight(style as Number) as Boolean {
        return (style == LIGHT);
    }
}
