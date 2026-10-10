import Toybox.Graphics;
import Toybox.Lang;

//! The face but the seconds, drawn off screen once a minute: a full update
//! copies all of it, a partial update only the box round the seconds.
//! The system may take the bitmap back; it is then made anew and redrawn.
//! Out of date, it is what the screen last got, so still right to copy
//! back under the seconds.
class FaceBuffer {

    private const NO_MINUTE = -1;

    private var screenWidth as Number = 0;
    private var screenHeight as Number = 0;
    private var reference as BufferedBitmapReference? = null;

    //! The Clock.minuteOfDay() it was last drawn for
    private var drawnMinute as Number = NO_MINUTE;

    //! Whether the bitmap holds a face at all, however old
    private var hasFace as Boolean = false;

    function initialize() {
    }

    function prepare(dc as Dc) as Void {
        screenWidth = dc.getWidth();
        screenHeight = dc.getHeight();
        reference = null;
        hasFace = false;
        invalidate();
    }

    //! Draw it again before it is next used
    function invalidate() as Void {
        drawnMinute = NO_MINUTE;
    }

    function isCurrent(minute as Number) as Boolean {
        return minute == drawnMinute;
    }

    function markDrawn(minute as Number) as Void {
        drawnMinute = minute;
        hasFace = true;
    }

    //! The face as last drawn, however old, neither made nor drawn here: a
    //! partial update cannot afford either. Null when there is none.
    function lastDrawn() as BufferedBitmap? {
        var current = reference;

        if ((current == null) || !hasFace) {
            return null;
        }

        return current.get() as BufferedBitmap?;
    }

    //! Null when the graphics pool has no room for it
    function bitmap() as BufferedBitmap? {
        var current = reference;

        if (current != null) {
            var kept = current.get();

            if (kept != null) {
                return kept as BufferedBitmap;
            }
        }

        // Lost or never made: whatever it held is gone.
        invalidate();
        hasFace = false;
        reference = Graphics.createBufferedBitmap({ :width => screenWidth, :height => screenHeight });

        return (reference as BufferedBitmapReference).get() as BufferedBitmap?;
    }
}
