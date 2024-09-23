﻿; scnviewer (for AgonLight)
;
; by B.Vignoli
; MIT 2024
;

; declarations
Declare LoadScreen(file$)

Global Dim pal.l(63)
Global palcount.l = 0

Global version$ = "1.0"

; create the window
If OpenWindow(0, 0, 0, 1024, 768, "scnviewer (v" + version$ + ")",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
  ; create the menu
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "&Load SCN" + Chr(9) + "Ctrl+O")
  EndIf
  
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_O, 1)
    
  ; create canvas gadget
  CanvasGadget(1, 0, 0, 1024, 768)
  
  ; no events
  ev = 0
  
  ; main loop
  Repeat
    ; wait for events
    ev = WaitWindowEvent()
    
    Select ev
      Case #PB_Event_Menu
        em = EventMenu()
        
        
        Select em
          Case 1
            ; request for a file name
            file$ = OpenFileRequester("Choose a SCN file to load", "", "SCN File|*.scn", 0)
            
            ; open the png file
            If file$ <> ""
              LoadScreen(file$)
            EndIf
        EndSelect
    EndSelect
  Until ev = #PB_Event_CloseWindow
  
  ; close the window
  CloseWindow(0)
Else
  ; error message
  MessageRequester("Error", "Can't open window !", #PB_MessageRequester_Error)
EndIf

; end program
End

Procedure LoadScreen(file$)
  If ReadFile(1, file$)
    mode.l = ReadByte(1)
    
    Restore Modes
    
    For i = 0 To mode
      Read.l width
      Read.l height
      Read.l palcount
    Next
    
    StartDrawing(CanvasOutput(1))
    DrawingMode(#PB_2DDrawing_AllChannels)
    
    Box(0, 0, 1024, 768, RGBA(128, 128, 128, 255))
    
    For i = 0 To palcount - 1
      r.a = ReadByte(1)
      g.a = ReadByte(1)
      b.a = ReadByte(1)
      
      pal(i) = RGBA(r, g, b, 255)
    Next
    
    crunched.l = ReadByte(1)
    
    If crunched = 0
      For y.l = 0 To height - 1
        For x.l = 0 To width - 1
          c.l = ReadByte(1)

          Plot(x, y, pal(c))
        Next
      Next
    Else
    EndIf
    
    StopDrawing()
    CloseFile(1)
  Else
    MessageRequester("Error", "Can't find screen file !", #PB_MessageRequester_Error)
  EndIf
EndProcedure

; data
DataSection
  Modes:
    Data.l 640, 480, 16
    Data.l 640, 480, 4
    Data.l 640, 480, 2
    Data.l 640, 240, 64
    Data.l 640, 240, 16
    Data.l 640, 240, 4
    Data.l 640, 240, 2
    Data.l 0, 0, 16
    Data.l 320, 240, 64
    Data.l 320, 240, 16
    Data.l 320, 240, 4
    Data.l 320, 240, 2
    Data.l 320, 200, 64
    Data.l 320, 200, 16
    Data.l 320, 200, 4
    Data.l 320, 200, 2
    Data.l 800, 600, 4
    Data.l 800, 600, 2
    Data.l 1024, 768, 2
    Data.l 1024, 768, 4
    Data.l 512, 384, 64
    Data.l 512, 384, 16
    Data.l 512, 384, 4
    Data.l 512, 384, 2
EndDataSection

; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 43
; FirstLine = 30
; Folding = -
; EnableXP
; DPIAware
; Executable = scnviewer.exe