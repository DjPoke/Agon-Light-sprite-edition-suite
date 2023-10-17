png2scn
=======

This tool for Agon Light computers converts png images to a screen's data.
It uses the default 64 colors palette.

In this archive, you can find this palette as a .pal file for Aseprite
and Pro Motion NG.

png2scn is programmed with Purebasic 6.0.3, runs under Windows, and can
easily be compiled for Mac (intel, M1/M2), Linux and Raspberry Pi.

screen structure:
=================
colors count  : byte
screen width  : word
screen height : word
data          : width x height bytes of colors


DjPoke
