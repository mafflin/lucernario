import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! The wind as an arrow in the status row, turned to the bearing, strength
//! said with color - see WindReading. Drawn as three corners rather than a
//! turned bitmap: the bilinear filter makes part-opaque pixels a MIP panel
//! cannot composite, so a turned bitmap's tail wobbles with the bearing.
class Wind extends Icon {

    //! Corners on the 24 unit grid the SVGs use, scaled to the row's square.
    //! Whole units so every corner lands on a pixel at 24 and 36; the right
    //! wing mirrors the left. A convex triangle: a notched dart would need
    //! two polygons, and smoothing leaves a seam where they meet.
    private const GRID = 24.0;
    private const MIDDLE = GRID / 2;
    private const APEX_X = 12;
    private const APEX_Y = 2;
    private const WING_X = 4;
    private const WING_Y = 20;

    private var windReading as WindReading;
    private var enabled as Boolean = true;

    //! The square the row gives this icon
    private var square as Number = 0;

    //! Corners about the square's middle, held until the bearing moves
    private var corners as Array< Array<Float> >? = null;
    private var cornersBearing as Number? = null;

    function initialize(windReading as WindReading) {
        Icon.initialize(null);
        self.windReading = windReading;
    }

    //! false while the dial shows the bearing instead
    function setEnabled(enabled as Boolean) as Void {
        self.enabled = enabled;
    }

    function isReporting(settings as System.DeviceSettings) as Boolean {
        return enabled && (windReading.bearing() != null);
    }

    //! No bitmap to measure: the size is the build's, 24px or 36px
    function setSquare(size as Number) as Void {
        if (size == square) {
            return;
        }

        square = size;
        corners = null;
    }

    function width() as Number {
        return square;
    }

    function height() as Number {
        return square;
    }

    protected function tint() as Number {
        return windReading.colorFor(Icon.tint());
    }

    protected function paint(dc as Dc, x as Number, y as Number) as Void {
        if (square == 0) {
            return;
        }

        var offsets = currentCorners();
        var middleX = x + (square / 2.0);
        var middleY = y + (square / 2.0);

        dc.setColor(tint(), Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [Dial.pixel(middleX + offsets[0][0]), Dial.pixel(middleY + offsets[0][1])],
            [Dial.pixel(middleX + offsets[1][0]), Dial.pixel(middleY + offsets[1][1])],
            [Dial.pixel(middleX + offsets[2][0]), Dial.pixel(middleY + offsets[2][1])]
        ]);
    }

    //! Worked out again only when the bearing or the square moves
    private function currentCorners() as Array< Array<Float> > {
        var bearing = windReading.bearing();

        if ((corners == null) || (bearing != cornersBearing)) {
            corners = cornersFor(bearing);
            cornersBearing = bearing;
        }

        return corners as Array< Array<Float> >;
    }

    //! Apex first, turned to point downwind
    private function cornersFor(bearing as Number?) as Array< Array<Float> > {
        // Screen y grows downward, so a positive angle is clockwise, as a
        // compass counts.
        var angle = 0.0;

        // The bearing is where the wind comes from; the arrow points where it goes.
        if (bearing != null) {
            angle = Math.toRadians(bearing + Dial.HALF_TURN).toFloat();
        }

        return [
            corner(APEX_X, APEX_Y, angle),
            corner(WING_X, WING_Y, angle),
            corner(GRID - WING_X, WING_Y, angle)
        ];
    }

    //! A grid point as an offset from the square's middle, turned by angle
    private function corner(gridX as Numeric, gridY as Numeric, angle as Float) as Array<Float> {
        var scale = square / GRID;
        var dx = ((gridX - MIDDLE) * scale).toFloat();
        var dy = ((gridY - MIDDLE) * scale).toFloat();
        var sine = Math.sin(angle).toFloat();
        var cosine = Math.cos(angle).toFloat();

        return [
            (dx * cosine) - (dy * sine),
            (dx * sine) + (dy * cosine)
        ];
    }
}
