png2spr
=======

This tool for Agon Light computers converts PNG images to sprite data.

How does it works ?
-------------------
1) Import your sprite. If the sprite is an animstrip, it must be full horizontal or vertical animstrip.
2) Import the palette.
3) Export the animated sprite.

png2spr is programmed with Purebasic 6.1.2, runs under Windows, and can
easily be compiled for Mac (intel, M1/M2), Linux and Raspberry Pi.

sprite structure:
=================
colors count : byte
frames count : byte
spr size	 : byte
data         : width x height bytes of colors (color numbers from the palette)


DjPoke
