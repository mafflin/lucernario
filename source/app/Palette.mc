import Toybox.Lang;

//! The colors the code names, under the names strings.xml gives them and
//! with the values watchface.xml gives them. Every channel is 00, 55, AA or
//! FF - the 64 color MIP palette - so none of these dither on those screens.
//!
//! The palette the user picks from lives in watchface.xml, which the code
//! cannot read a value out of, so what the code needs is repeated here and
//! must stay in step with it.
module Palette {
    const AMBER = 0xFFAA00;
    const DARK_SKY = 0x0055AA;
}
