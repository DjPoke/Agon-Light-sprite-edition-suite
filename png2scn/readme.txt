png2scn (v3)
===========

This tool for Agon Light computers converts png images to a screen's data.
Images must be a Bitmap with 2,4,16 or 64 colors, corresponding to the
mode you'll use in your AgonLight.

png2scn is programmed with Purebasic 6.1.2, runs under Windows, and can
easily be compiled for Mac (intel, M1/M2), Linux and Raspberry Pi.

screen structure:
=================
mode		: 0-23 (can be used with other double buffered modes)
palette		: RGB colors(depending on the selected mode)
type		: 0 for RAW screen, 1 for crunched screen
data		: bytes of colors (can be RAW data or crunched screen)

DjPoke
