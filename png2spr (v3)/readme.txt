png2spr v2
==========

This tool for Agon Light computers converts png images to sprite data.
It uses the default 64 colors palette.

The 2nd version of png2spr is not directly compatible with spredit,
as you can set differents width and height for the sprite you convert.

In this archive, you can find this palette as a .pal file for Aseprite
and Pro Motion NG.

png2spr is programmed with Purebasic 6.0.3, runs under Windows, and can
easily be compiled for Mac (intel, M1/M2), Linux and Raspberry Pi.

sprite structure:
=================
frames count : byte
spr width    : byte
spr height   : byte
data         : width x height bytes of colors


DjPoke
