png2tileset
===========

This tool for Agon Light computers converts PNG images to tilesets.

How does it works ?
-------------------
1) Import your sprite. If the sprite is an animstrip, it must be full horizontal or vertical animstrip.
2) Import the palette.
3) Export the tileset.

png2tileset is programmed with Purebasic 6.1.2, runs under Windows, and can
easily be compiled for Mac (intel, M1/M2), Linux and Raspberry Pi.

tileset structure:
=================
colors count : byte
tiles count  : byte
tiles size	 : byte
data         : tile after tile width x height bytes of colors (color numbers from the palette)


DjPoke
