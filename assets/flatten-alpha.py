#!/usr/bin/env python3
"""Flatten a PNG's alpha channel to fully on or fully off.

Reads an RGBA PNG on stdin and writes one on stdout. A pixel at or above the
cutoff comes out opaque white, everything else fully transparent; nothing in
between survives.

This is for the 24px icons, the ones that run on the MIP devices. Those
panels hold 64 colours and cannot composite, so an eight bit alpha channel is
no use to them: the watch reduces it to on or off as it draws, and it does a
poor job - see the alarm bell, whose ring breaks apart. Deciding here instead
means the artwork that ships is the artwork that appears.

The AMOLED icons are left alone. Those screens do composite, and their edges
are the reason they look right.

Needs no third party modules: the images are small and the format is only
used in its simplest form.
"""

import struct
import sys
import zlib

# A pixel is kept when the glyph covers a little under half of it. Not half:
# these strokes are two units wide on a 24 unit grid, so at 24px they are 2px
# wide, and a stroke that thin loses a side to a cutoff of half. 128 thinned
# the clock face inside the alarm and broke the phone's handset where it
# crosses the diagonal; 160 dropped pixels out of the clock hands. Below about
# 96 the bell's feet merge into its ring.
CUTOFF = 112


def read_rgba(data):
    """Width, height and RGBA rows of an 8 bit RGBA PNG."""
    position, stream, width, height = 8, b"", None, None

    while position < len(data):
        length = struct.unpack(">I", data[position:position + 4])[0]
        kind = data[position + 4:position + 8]
        chunk = data[position + 8:position + 8 + length]

        if kind == b"IHDR":
            width, height, depth, color = struct.unpack(">IIBB", chunk[:10])
            if (depth, color) != (8, 6):
                sys.exit("flatten-alpha: expected 8 bit RGBA, got depth %d"
                         " type %d" % (depth, color))
        elif kind == b"IDAT":
            stream += chunk

        position += 12 + length

    raw = zlib.decompress(stream)
    stride = width * 4
    rows = []
    previous = bytearray(stride)
    position = 0

    # Undo the per row filter. rsvg-convert picks whichever it likes, so all
    # five have to be handled.
    for _ in range(height):
        method = raw[position]
        position += 1
        row = bytearray(raw[position:position + stride])
        position += stride

        for x in range(stride if method else 0):
            left = row[x - 4] if x >= 4 else 0
            above = previous[x]
            corner = previous[x - 4] if x >= 4 else 0

            if method == 1:
                row[x] = (row[x] + left) & 0xFF
            elif method == 2:
                row[x] = (row[x] + above) & 0xFF
            elif method == 3:
                row[x] = (row[x] + ((left + above) >> 1)) & 0xFF
            elif method == 4:
                estimate = left + above - corner
                near = (abs(estimate - left), abs(estimate - above),
                        abs(estimate - corner))
                nearest = (left, above, corner)[near.index(min(near))]
                row[x] = (row[x] + nearest) & 0xFF
            else:
                sys.exit("flatten-alpha: unknown row filter %d" % method)

        rows.append(row)
        previous = row

    return width, height, rows


def flatten(width, rows):
    """Every pixel opaque white or fully clear, nothing in between."""
    out = bytearray()

    for row in rows:
        out.append(0)  # no filter: these rows are mostly runs already

        for x in range(width):
            if row[x * 4 + 3] >= CUTOFF:
                out += b"\xFF\xFF\xFF\xFF"
            else:
                out += b"\x00\x00\x00\x00"

    return bytes(out)


def chunk(kind, payload):
    return (struct.pack(">I", len(payload)) + kind + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF))


def main():
    width, height, rows = read_rgba(sys.stdin.buffer.read())

    sys.stdout.buffer.write(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(flatten(width, rows), 9))
        + chunk(b"IEND", b""))


if __name__ == "__main__":
    main()
