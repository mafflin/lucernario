import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! The wind on the dial: an equilateral triangle the size of the seconds
//! hand, standing on the rim at the bearing, pointing the way it blows.
//! Accent color for a light wind, then orange and red - see WindReading.
//! Reaching past the marks, it is put back when the seconds hand's clip
//! cuts into it.
class WindBearing {

    private var windReading as WindReading;
    private var enabled as Boolean = false;

    //! For a light wind
    private var lightColor as Number = Graphics.COLOR_WHITE;

    //! Base width, and half the angle its ends span on the rim
    private var baseWidth as Float = 0.0;
    private var halfSpread as Float = 0.0;

    //! As last drawn, so a partial update can put it back
    private var shown as Boolean = false;
    private var corners as Array<[Numeric, Numeric]>;
    private var drawnColor as Number = Graphics.COLOR_WHITE;
    private var box as Box;
    private var placedBearing as Number? = null;

    function initialize(windReading as WindReading) {
        self.windReading = windReading;
        corners = [[0, 0], [0, 0], [0, 0]] as Array<[Numeric, Numeric]>;
        box = new Box();
    }

    //! After Dial.setup()
    function prepare(width as Float) as Void {
        baseWidth = width;

        // The base is a chord of the rim.
        halfSpread = Math.asin(width / (2 * Dial.rim)).toFloat();
        placedBearing = null;
    }

    function setEnabled(enabled as Boolean) as Void {
        self.enabled = enabled;
    }

    function setColor(color as Number) as Void {
        lightColor = color;
    }

    function draw(dc as Dc) as Void {
        var bearing = windReading.bearing();

        shown = false;

        if (!enabled || (bearing == null)) {
            return;
        }

        shown = true;

        if (bearing != placedBearing) {
            place(bearing);
        }

        drawnColor = windReading.colorFor(lightColor);
        paint(dc);
    }

    //! Put it back if the clip has cut into it
    function redraw(dc as Dc) as Void {
        if (shown && ClipRegion.covers(box)) {
            paint(dc);
        }
    }

    private function paint(dc as Dc) as Void {
        RimPainter.fill(dc, corners, drawnColor);
    }

    //! A compass bearing reads as clockwise from the top of the dial
    private function place(bearing as Number) as Void {
        var middle = Dial.radiansOf(bearing);
        var tipRadius = Dial.rim - (baseWidth * RimPainter.EQUILATERAL_HEIGHT);

        setCorner(0, middle + halfSpread, Dial.rim);
        setCorner(1, middle - halfSpread, Dial.rim);
        setCorner(2, middle, tipRadius);
        placedBearing = bearing;

        box.aroundPoints(corners, 0);
    }

    private function setCorner(index as Number, radians as Decimal, radius as Numeric) as Void {
        corners[index] = [Dial.pointX(radians, radius), Dial.pointY(radians, radius)];
    }
}
