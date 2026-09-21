#!/bin/sh
# Regenerates the icon PNGs the build consumes from assets/icons/*.svg.
#
# Run from the repository root:
#
#     sh assets/generate-icons.sh
#
# The artwork is black on transparent, and the face tints it at draw time, so
# every path is refilled white on the way through: an untinted icon has to be
# visible on the dark style, and a black one would not be. See Icon.paint.
#
# Two sizes, 24px in resources/ and 36px in resources-large-icons/, selected
# by the resourcePath lines in monkey.jungle. The small set is also flattened
# to hard edges, which the large set is not - see the note above pair().
#
# Needs rsvg-convert (librsvg) and python3.

set -e

SRC=assets/icons
SMALL=resources/drawables
LARGE=resources-large-icons/drawables
FLATTEN=assets/flatten-alpha.py

# The source with every path refilled white and the viewBox replaced.
#   $1 source svg   $2 viewBox
artwork() {
    sed -e 's|<path |<path fill="#FFFFFF" |g' \
        -e "s|viewBox=\"[^\"]*\"|viewBox=\"$2\"|" \
        "$SRC/$1"
}

# One icon, at one size.
#   $1 source svg   $2 destination png   $3 width   $4 height   $5 viewBox
#   $6 "flat" to reduce the edges to on or off, empty to keep them
render() {
    mkdir -p "$(dirname "$2")"

    if [ "$6" = "flat" ]; then
        artwork "$1" "$5" \
        | rsvg-convert -w "$3" -h "$4" -b none \
        | python3 "$FLATTEN" > "$2"
    else
        artwork "$1" "$5" | rsvg-convert -w "$3" -h "$4" -b none -o "$2"
    fi
}

# The square icons fill their 24 unit box, so they render as it stands.
BOX="0 0 24 24"

# One icon into both sizes.
#
# Only the small set is flattened. Those 24px icons are what the MIP devices
# get, and a MIP panel holds 64 colours and cannot composite: it reduces an
# alpha channel to on or off as it draws, badly, so the decision is taken
# here instead. The 36px set keeps its edges, because the AMOLED screens it
# goes to do composite them.
#   $1 source svg   $2 path under drawables
pair() {
    render "$1" "$SMALL/$2" 24 24 "$BOX" flat
    render "$1" "$LARGE/$2" 36 36 "$BOX"
}

pair alarm.svg alarm/alarm.png
pair phone.svg phone/phone.png

# direction.svg is not rendered any more: the wind arrow is three corners
# turned and filled in source/Wind.mc, which is the only way it comes out
# straight on a MIP panel. The file stays as the drawing those corners were
# taken off.

for level in 0 10 20 30 40 50 60 70 80 90 100; do
    pair "battery-$level.svg" "battery/battery_$level.png"
done

# AM and PM are letters, not a symbol: the art is 18 units by 10 inside the
# same 24 unit box, so rendering it square would leave a small pair of letters
# in a lot of empty space. The box is cropped to the letters instead and
# padded back out, which is what gives these two their own dimensions.
#
# The small box is the one the flattening cares about. Every edge in these two
# glyphs sits on an odd unit - the stems run 3 to 5, 11 to 13, 15 to 17, 19 to
# 21 - so at scale 1.5 from an odd origin every one of them lands on a whole
# pixel and all five stems come out 3px. Off that grid they come out 3 and 4
# about equally, which is what the letters used to do. 22 units by 14 is the
# letters' own 18 by 10 plus 2 units of padding, and 1,5 is the odd origin.
#
# The large box is left as it was: nothing flattens it, so landing it on the
# grid buys nothing, and moving it would resize the icon on every AMOLED
# device. Those numbers are the letters' bounds grown to the ratio of 49:30.
MERIDIEM_SMALL="1 5 22 14"
MERIDIEM_LARGE="1.684 5.684 20.632 12.632"

render meridiem-am.svg "$SMALL/meridiem/am.png" 33 21 "$MERIDIEM_SMALL" flat
render meridiem-pm.svg "$SMALL/meridiem/pm.png" 33 21 "$MERIDIEM_SMALL" flat
render meridiem-am.svg "$LARGE/meridiem/am.png" 49 30 "$MERIDIEM_LARGE"
render meridiem-pm.svg "$LARGE/meridiem/pm.png" 49 30 "$MERIDIEM_LARGE"

# The launcher icon is drawn by the system and never tinted, so it is not
# flattened either: the system scales it to whatever each device asks for, and
# that scaling wants the edges. It is white for the same reason as the rest,
# the app list being dark. 65x65 is what fenix847mm asks for; a device wanting
# another size scales it and warns at build time.
render launcher_icon.svg "$SMALL/launcher_icon.png" 65 65 "$BOX"

echo "Icons regenerated."
