import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! Picks the largest font a screen can carry for a given string.
//!
//! Vector fonts scale freely, so the best size is found by binary search.
//! Devices without them fall back to the largest system font that fits.
module FontFitter {

    //! Vector font faces to try, in order of preference. getVectorFont takes
    //! the list and answers with the first face the device carries, so the
    //! ones behind are the fallback for a device without the first.
    //!
    //! Regular leads: a lighter, wider face than the condensed bold that used
    //! to. It will be fitted at a smaller size, because on a round screen the
    //! fit is bound by width.
    const VECTOR_FACES = ["RobotoRegular", "RobotoCondensedBold", "RobotoBold"];

    //! Smallest vector font worth considering, in pixels. Below this the text
    //! would be unreadable anyway.
    const MIN_VECTOR_SIZE = 8;

    //! Returned by the search when no size fit at all
    const NO_SIZE = 0;

    //! Portion of the space the text may occupy. Callers pass an inset for
    //! whatever is drawn around the edge, so this is only the slack that
    //! covers what measuring cannot: side bearings, rounding, a font whose
    //! metrics run large.
    const FILL_RATIO = 0.98;

    //! The largest font that can draw the given text within the screen bounds
    //! @param dc The drawing context
    //! @param text The string that has to fit
    //! @param inset Pixels to keep clear around the edge of the screen, for
    //!        whatever else is drawn out there
    //! @return The font to draw with
    function largestFor(dc as Dc, text as String, inset as Number) as FontType {
        if (Graphics has :getVectorFont) {
            var font = largestVectorFor(dc, text, inset);
            if (font != null) {
                return font;
            }
        }

        return largestSystemFor(dc, text, inset);
    }

    //! Binary search the largest vector font size that still fits
    //! @param dc The drawing context
    //! @param text The string that has to fit
    //! @param inset Pixels to keep clear around the edge of the screen
    //! @return The vector font, or null if the device has none of our faces
    function largestVectorFor(dc as Dc, text as String, inset as Number) as VectorFont? {
        var bestSize = NO_SIZE;
        var smallest = MIN_VECTOR_SIZE;

        // A glyph can never be taller than the screen, so that is the ceiling.
        var largest = dc.getHeight();

        while (smallest <= largest) {
            var size = (smallest + largest) / 2;

            if (vectorFits(dc, size, text, inset)) {
                bestSize = size;
                smallest = size + 1;
            } else {
                largest = size - 1;
            }
        }

        if (bestSize == NO_SIZE) {
            return null;
        }

        return vectorFontOf(bestSize);
    }

    //! Pick the largest system font that fits, from biggest to smallest
    //! @param dc The drawing context
    //! @param text The string that has to fit
    //! @param inset Pixels to keep clear around the edge of the screen
    //! @return The font to draw with
    function largestSystemFor(dc as Dc, text as String, inset as Number) as FontType {
        var ladder = [
            Graphics.FONT_NUMBER_THAI_HOT,
            Graphics.FONT_NUMBER_HOT,
            Graphics.FONT_NUMBER_MEDIUM,
            Graphics.FONT_NUMBER_MILD,
            Graphics.FONT_LARGE,
            Graphics.FONT_MEDIUM,
            Graphics.FONT_SMALL
        ] as Array<FontType>;

        for (var i = 0; i < ladder.size(); i++) {
            if (fits(dc, ladder[i], text, inset)) {
                return ladder[i];
            }
        }

        return Graphics.FONT_TINY;
    }

    //! Whether a vector font of the given size can draw the text
    //! @param dc The drawing context
    //! @param size The vector font size to test, in pixels
    //! @param text The string that has to fit
    //! @param inset Pixels to keep clear around the edge of the screen
    //! @return true when a font of that size exists and fits
    function vectorFits(dc as Dc, size as Number, text as String, inset as Number) as Boolean {
        var font = vectorFontOf(size);

        if (font == null) {
            return false;
        }

        return fits(dc, font, text, inset);
    }

    //! Ask the device for a vector font of the given size
    //! @param size The font size in pixels
    //! @return The font, or null if no face is available at that size
    function vectorFontOf(size as Number) as VectorFont? {
        return Graphics.getVectorFont({ :face => VECTOR_FACES, :size => size });
    }

    //! Whether the text stays inside the display in the given font
    //! @param dc The drawing context
    //! @param font The font to measure with
    //! @param text The string that has to fit
    //! @param inset Pixels to keep clear around the edge of the screen
    //! @return true when the text fits both ways
    function fits(dc as Dc, font as FontType, text as String, inset as Number) as Boolean {
        var boxHeight = dc.getFontHeight(font);
        var textWidth = dc.getTextWidthInPixels(text, font);

        // The box has to sit on the screen, but only the glyphs themselves
        // have to clear the sides of a round one.
        return (boxHeight <= usableHeight(dc, inset))
            && (textWidth <= usableWidthAt(dc, inkHeightOf(dc, font), inset));
    }

    //! How tall the drawn glyphs actually are.
    //!
    //! Digits stand on the baseline and never reach below it, so the descent
    //! the font reserves is empty space. Measuring the round screen at the
    //! full font height would give away the width that empty space costs.
    //! @param dc The drawing context
    //! @param font The font to measure
    //! @return The height of the glyphs in pixels
    function inkHeightOf(dc as Dc, font as FontType) as Number {
        if (Graphics has :getFontAscent) {
            return Graphics.getFontAscent(font);
        }

        return dc.getFontHeight(font);
    }

    //! The vertical space text may occupy
    //! @param dc The drawing context
    //! @param inset Pixels kept clear around the edge of the screen
    //! @return The usable height in pixels
    function usableHeight(dc as Dc, inset as Number) as Float {
        return (dc.getHeight() - (2 * inset)) * FILL_RATIO;
    }

    //! The horizontal space a centered box of the given height may occupy.
    //! On a round display that is not the screen width but the chord across
    //! the circle at the box's corners, which is shorter.
    //! @param dc The drawing context
    //! @param textHeight The height of the glyphs to fit
    //! @param inset Pixels kept clear around the edge of the screen
    //! @return The usable width in pixels
    function usableWidthAt(dc as Dc, textHeight as Number, inset as Number) as Float {
        var width = dc.getWidth() - (2 * inset);

        if (System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_RECTANGLE) {
            return width * FILL_RATIO;
        }

        var radius = width / 2.0;
        var halfHeight = textHeight / 2.0;

        if (halfHeight >= radius) {
            return 0.0;
        }

        var chord = 2.0 * Math.sqrt(radius * radius - halfHeight * halfHeight);
        return (chord * FILL_RATIO).toFloat();
    }
}
