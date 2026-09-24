import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The numerals on the rim: every fourth hour, 24 at the top, then 4, 8, 12,
//! 16 and 20.
//!
//! Sat right against the inner ends of their marks, inside the ring the
//! seconds hand sweeps, and colored with the day as the marks are. Each is
//! turned the way the marks run, so a numeral always stands as deep as it
//! is tall. The top of the dial has its tops toward the glass; 8 through 16
//! are turned the other way up so they do not read upside down.
//!
//! Turned text wants a vector font and drawAngledText. A watch without them
//! gets the numerals upright in the smallest system font instead.
//!
//! The seconds hand crosses a numeral every ten seconds, so a partial update
//! puts back the one nearest where the hand has just been, if the clip has
//! cut into it. Only that one: the next nearest is sixty degrees off, far
//! out of the clip's reach.
class RimNumerals {

    //! Six numerals: every fourth hour, one per ten seconds of the hand
    private const _COUNT = 6;
    private const _HOURS_APART = Dial.HOUR_MARKS / _COUNT;
    private const _SECONDS_APART = Dial.SECONDS_PER_TURN / _COUNT;

    //! Air between the marks and the digits, as a share of the ring so it
    //! holds its proportions on every screen
    private const _GAP_DIVISOR = 5;

    //! The system font the vector one is sized off, and falls back to
    private const _FONT = Graphics.FONT_TINY;

    //! The vector font a touch smaller than that system font. The fallback
    //! is drawn at the system font's own size.
    private const _SIZE_NUMERATOR = 4;
    private const _SIZE_DIVISOR = 5;

    //! Faces to try for the turned numerals, in order: the first the watch
    //! carries is used
    private const _FACES = ["RobotoCondensedBold", "RobotoCondensedRegular", "RobotoRegular", "Swiss721Regular"];

    private const _JUSTIFY = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    //! The font the numerals are drawn in, and whether it can be turned
    private var _font as FontType = _FONT;
    private var _turned as Boolean = false;

    //! Each numeral's text, where its middle is anchored, how far it is
    //! turned, and the box around it for the clip test, resolved in prepare()
    private var _texts as Array<String>;
    private var _xs as Array<Number>;
    private var _ys as Array<Number>;
    private var _angles as Array<Number>;
    private var _boxes as Array<Box>;

    //! The colors of the day, shared with the marks
    private var _dayColors as DayColors;

    //! Whether the top numeral is left off, set in draw()
    private var _topHidden as Boolean = false;

    //! Each numeral's color, taken in draw() so a partial update puts one
    //! back as it was without working it out again
    private var _colors as Array<Number>;

    //! Constructor
    //! @param dayColors The colors of the day
    function initialize(dayColors as DayColors) {
        _dayColors = dayColors;
        _colors = new [_COUNT] as Array<Number>;
        _texts = new [_COUNT] as Array<String>;
        _xs = new [_COUNT] as Array<Number>;
        _ys = new [_COUNT] as Array<Number>;
        _angles = new [_COUNT] as Array<Number>;
        _boxes = new [_COUNT] as Array<Box>;

        for (var i = 0; i < _COUNT; i++) {
            // Midnight reads as the full count rather than zero.
            var hour = (i == 0) ? Dial.HOUR_MARKS : (i * _HOURS_APART);

            _texts[i] = hour.toString();
            _boxes[i] = new Box();
        }
    }

    //! Pick the font and place the numerals against the marks. The digits
    //! stand on the baseline, so the ink runs from the top of the box to the
    //! ascent; the descent below is empty. Run after Dial.setup().
    //! @param dc The drawing context
    //! @param markReach How far in from the rim the marks come
    function prepare(dc as Dc, markReach as Number) as Void {
        chooseFont(dc);

        var ink = Fonts.inkHeightOf(dc, _font);
        var height = dc.getFontHeight(_font);

        // Centered on its whole box, a numeral's digits sit half the empty
        // descent toward its top: shift the anchor away from the top by that
        // much so the digits, not the box, are centered in their stretch of
        // the ring. Upright numerals have their top toward the glass, flipped
        // ones toward the middle.
        var descent = height - ink;
        var middle = Dial.rim - markReach - (Dial.ringDepth / _GAP_DIVISOR) - (ink / 2);

        for (var i = 0; i < _COUNT; i++) {
            var degrees = positionOf(i);
            var flipped = _turned && isUpsideDown(degrees);
            var radius = flipped ? (middle + (descent / 2)) : (middle - (descent / 2));
            var radians = Dial.radiansOf(degrees);
            var width = dc.getTextWidthInPixels(_texts[i], _font);

            _xs[i] = Dial.pointX(radians, radius);
            _ys[i] = Dial.pointY(radians, radius);
            _angles[i] = _turned ? angleOf(degrees, flipped) : 0;

            boxAround(i, width, height);
        }
    }

    //! Draw every numeral
    //! @param dc The drawing context
    //! @param hideTop Whether to leave off the 24, for the system's activity
    //!        indicator that sits over it
    function draw(dc as Dc, hideTop as Boolean) as Void {
        _topHidden = hideTop;

        for (var i = 0; i < _COUNT; i++) {
            _colors[i] = _dayColors.colorAt(positionOf(i));

            if (isShown(i)) {
                paint(dc, i);
            }
        }
    }

    //! Put back the numeral nearest where the hand has just been, if the
    //! clip has cut into it
    //! @param dc The drawing context
    //! @param second Where the hand has just been
    function redraw(dc as Dc, second as Number) as Void {
        var i = ((second + (_SECONDS_APART / 2)) / _SECONDS_APART) % _COUNT;

        if (isShown(i) && ClipRegion.covers(_boxes[i])) {
            paint(dc, i);
        }
    }

    //! Whether a numeral is on screen as of the last draw()
    //! @param i Which numeral, counting clockwise from the top
    //! @return true unless it is the top one and that is left off
    private function isShown(i as Number) as Boolean {
        return (i != 0) || !_topHidden;
    }

    //! Draw one numeral in its color
    //! @param dc The drawing context
    //! @param i Which numeral, counting clockwise from the top
    private function paint(dc as Dc, i as Number) as Void {
        dc.setColor(_colors[i], Graphics.COLOR_TRANSPARENT);

        if (_turned) {
            dc.drawAngledText(_xs[i], _ys[i], _font as VectorFont, _texts[i], _JUSTIFY, _angles[i]);
        } else {
            dc.drawText(_xs[i], _ys[i], _font, _texts[i], _JUSTIFY);
        }
    }

    //! Where a numeral sits on the dial
    //! @param i Which numeral, counting clockwise from the top
    //! @return The position in degrees, clockwise from midnight
    private function positionOf(i as Number) as Number {
        return i * _HOURS_APART * Dial.DEGREES_PER_HOUR_MARK;
    }

    //! Whether a numeral turned to follow the marks would read upside down:
    //! the bottom of the dial, 8 through 16, past a quarter turn either side
    //! of the top.
    //! @param degrees Where it sits, clockwise from midnight
    //! @return true when it wants flipping
    private function isUpsideDown(degrees as Number) as Boolean {
        return (degrees > Dial.QUARTER_TURN) && (degrees < (Dial.DEGREES_PER_CIRCLE - Dial.QUARTER_TURN));
    }

    //! How far to turn a numeral: counterclockwise, the way drawAngledText
    //! turns, so one at three o'clock on the dial is turned a quarter
    //! clockwise. A flipped one is turned half a turn more, to read upright
    //! with its top toward the middle.
    //! @param degrees Where it sits, clockwise from midnight
    //! @param flipped Whether it reads the other way up
    //! @return The angle in degrees, within one turn
    private function angleOf(degrees as Number, flipped as Boolean) as Number {
        var angle = Dial.DEGREES_PER_CIRCLE - degrees;

        if (flipped) {
            angle += Dial.HALF_TURN;
        }

        return angle % Dial.DEGREES_PER_CIRCLE;
    }

    //! A vector font sized off the system one, if the watch can turn text in
    //! it; the system font upright otherwise
    //! @param dc The drawing context
    private function chooseFont(dc as Dc) as Void {
        _font = _FONT;
        _turned = false;

        if (!(Graphics has :getVectorFont) || !(dc has :drawAngledText)) {
            return;
        }

        var font = Graphics.getVectorFont({
            :face => _FACES,
            :size => dc.getFontHeight(_FONT) * _SIZE_NUMERATOR / _SIZE_DIVISOR
        });

        if (font != null) {
            _font = font;
            _turned = true;
        }
    }

    //! The upright box a numeral fills once turned: its own box, turned, and
    //! boxed again
    //! @param i Which numeral
    //! @param width The text's width
    //! @param height The text's height
    private function boxAround(i as Number, width as Number, height as Number) as Void {
        var radians = Math.toRadians(_angles[i]);
        var cosine = Math.cos(radians).abs();
        var sine = Math.sin(radians).abs();

        _boxes[i].aroundCenter(
            _xs[i],
            _ys[i],
            Dial.pixel((width * cosine) + (height * sine)),
            Dial.pixel((width * sine) + (height * cosine))
        );
    }
}
