png2scn v2
==========

This tool for Agon Light computers converts png images to a screen's data.
Images must be 32 bits RGBA True color PNG, or the program will fail silently.

png2scn is programmed with Purebasic 6.0.3, runs under Windows, and can
easily be compiled for Mac (intel, M1/M2), Linux and Raspberry Pi.

screen structure:
=================
rgba		  : byte, equal to 8, 2 or 1 (rgba8888, rgba2222 or rgba1111)
screen width  : word
screen height : word
data          : bytes of colors


DjPoke
