import Toybox.Graphics;
import Toybox.Lang;

//! 24, 4, 8, 12, 16 and 20 clockwise from the top, against the inner ends of
//! their marks, colored with the day. Turned to follow the marks, 8 through 16
//! flipped so they do not read upside down; a watch without vector fonts gets
//! them upright. Left off on Plain.
class RimNumerals {

    private const COUNT = 6;
    private const HOURS_APART = Dial.HOUR_MARKS / COUNT;

    //! Midnight - see Dial.MIDNIGHT_DEGREES
    private const TOP_HOUR = 0;

    //! Air between the marks and the digits, as a share of the ring
    private const GAP_DIVISOR = 5;

    //! The system font the vector one is sized off, and falls back to
    private const SYSTEM_FONT = Graphics.FONT_TINY;

    //! The vector font a touch smaller than the system one
    private const SIZE_NUMERATOR = 4;
    private const SIZE_DIVISOR = 5;

    //! In order: the first the watch carries is used
    private const FACES = ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular", "Swiss721Regular"];

    private const JUSTIFY = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    private var font as FontType = SYSTEM_FONT;
    private var isTurned as Boolean = false;

    //! Per numeral, resolved in prepare()
    private var texts as Array<String>;
    private var xs as Array<Number>;
    private var ys as Array<Number>;
    private var angles as Array<Number>;

    private var dayColors as DayColors;
    private var enabled as Boolean = true;

    //! The 24 is left off while the system's activity indicator sits over it
    private var topHidden as Boolean = false;

    function initialize(dayColors as DayColors) {
        self.dayColors = dayColors;
        texts = new [COUNT] as Array<String>;
        xs = new [COUNT] as Array<Number>;
        ys = new [COUNT] as Array<Number>;
        angles = new [COUNT] as Array<Number>;

        for (var index = 0; index < COUNT; index++) {
            texts[index] = hourAt(index).toString();
        }
    }

    //! After Dial.setup()
    function prepare(dc as Dc, markReach as Number) as Void {
        chooseFont(dc);

        var fontHeight = dc.getFontHeight(font);
        var ink = Fonts.inkHeightOf(font);
        var middle = Dial.rim - markReach - (Dial.ringDepth / GAP_DIVISOR) - (ink / 2);

        // Center the digits, not the font box: shift the anchor by half the
        // empty descent.
        var shift = (fontHeight - ink) / 2;

        for (var index = 0; index < COUNT; index++) {
            place(index, middle, shift);
        }
    }

    function setEnabled(enabled as Boolean) as Void {
        self.enabled = enabled;
    }

    function draw(dc as Dc, hideTop as Boolean) as Void {
        topHidden = hideTop;

        for (var index = 0; index < COUNT; index++) {
            if (isShown(index)) {
                paint(dc, index);
            }
        }
    }

    //! The empty descent lies toward the middle for upright numerals and
    //! toward the glass for flipped ones
    private function place(index as Number, middle as Number, shift as Number) as Void {
        var degrees = positionOf(index);
        var flipped = isTurned && isUpsideDown(degrees);
        var radius = flipped ? (middle + shift) : (middle - shift);
        var radians = Dial.radiansOf(degrees);

        xs[index] = Dial.pointX(radians, radius);
        ys[index] = Dial.pointY(radians, radius);
        angles[index] = isTurned ? angleOf(degrees, flipped) : 0;
    }

    private function isShown(index as Number) as Boolean {
        return enabled && ((index != 0) || !topHidden);
    }

    private function paint(dc as Dc, index as Number) as Void {
        dc.setColor(dayColors.colorAt(positionOf(index)), Graphics.COLOR_TRANSPARENT);

        if (isTurned) {
            dc.drawAngledText(xs[index], ys[index], font as VectorFont, texts[index], JUSTIFY, angles[index]);
        } else {
            dc.drawText(xs[index], ys[index], font, texts[index], JUSTIFY);
        }
    }

    //! The hour a numeral reads, midnight as 24, not 0
    private function hourAt(index as Number) as Number {
        var hour = ((index * HOURS_APART) + TOP_HOUR) % Dial.HOUR_MARKS;

        return (hour == 0) ? Dial.HOUR_MARKS : hour;
    }

    //! Degrees clockwise from the top
    private function positionOf(index as Number) as Number {
        return index * HOURS_APART * Dial.DEGREES_PER_HOUR_MARK;
    }

    //! The bottom of the dial, past a quarter turn either side of the top
    private function isUpsideDown(degrees as Number) as Boolean {
        return (degrees > Dial.QUARTER_TURN) && (degrees < (Dial.DEGREES_PER_CIRCLE - Dial.QUARTER_TURN));
    }

    //! Counterclockwise, the way drawAngledText turns; flipped ones half a
    //! turn more
    private function angleOf(degrees as Number, flipped as Boolean) as Number {
        var angle = Dial.DEGREES_PER_CIRCLE - degrees;

        if (flipped) {
            angle += Dial.HALF_TURN;
        }

        return angle % Dial.DEGREES_PER_CIRCLE;
    }

    //! A vector font if the watch carries one of the faces, the system font
    //! upright otherwise
    private function chooseFont(dc as Dc) as Void {
        font = SYSTEM_FONT;
        isTurned = false;

        var vectorFont = Graphics.getVectorFont({
            :face => FACES,
            :size => dc.getFontHeight(SYSTEM_FONT) * SIZE_NUMERATOR / SIZE_DIVISOR
        });

        if (vectorFont != null) {
            font = vectorFont;
            isTurned = true;
        }
    }
}
