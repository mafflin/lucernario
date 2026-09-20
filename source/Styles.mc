import Toybox.Lang;

//! The style variations offered by the native watch face editor.
//!
//! The editor has no background setting, so the style id is what carries it.
//! These ids must match the <style> ids in resources/configs/watchface.xml.
module Styles {
    enum Value {
        DARK = 1,
        LIGHT = 2
    }

    //! Whether this style is dark on a light background rather than the other
    //! way round
    //! @param style The selected style
    //! @return true for the light style
    function isLight(style as Number) as Boolean {
        return (style == LIGHT);
    }
}
