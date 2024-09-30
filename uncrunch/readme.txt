cruncher/decruncher for ez80 (.scn files)
========================================

cases:
- lot of equals bytes
- lot of different bytes
- one byte

case 1: one byte > 0, no command, write the byte (same for a lot of different bytes)
case 2: one byte = 0, 0 become a command, write 0, 0 (cmd 0, value 0)
case 3: lot of equals bytes (cmd 0, count 1-255, value)


binary Agon decruncher can only decrunch 320x240 images, for now !
------------------------------------------------------------------
