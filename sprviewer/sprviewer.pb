; sprviewer (for AgonLight)
;
; by B.Vignoli
; MIT 2024
;

; declarations
Declare LoadSpr(file$)
Declare LoadPalette(file$)

Global Dim pal.l(63)
Global palcount.l = 0
Global frames.l = 0
Global currentframe.l = 0
Global size.l = 0

Global version$ = "1.0"

; create the window
If OpenWindow(0, 0, 0, 256, 256 + MenuHeight(), "sprviewer (v" + version$ + ")",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
  ; create the menu
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "&Load Sprite and Palette" + Chr(9) + "Ctrl+O")
  EndIf
  
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_O, 1)
    
  ; create canvas gadget
  CanvasGadget(1, 0, 0, 256, 256)
  
  ; no events
  ev = 0
  
  ; main loop
  Repeat
    ; wait for events
    ev = WindowEvent()
    
    Select ev
      Case #PB_Event_Menu
        em = EventMenu()
       
        Select em
          Case 1
            ; request for a file name
            file1$ = OpenFileRequester("Choose a Sprite file to load", "", "SPR File|*.spr", 0)
            
            ; request for a file name
            file2$ = OpenFileRequester("Choose a Palette file to load", "", "PAL File|*.pal", 0)
            
            ; open the png file
            If file1$ <> "" And file2$ <> ""
              palcount = 0
              frames = 0
              currentframe = 1
              size = 0
              
              LoadPalette(file2$)
              LoadSpr(file1$)
            EndIf
        EndSelect
    EndSelect
    
    ; drawing animation
    If frames > 0
      cptframes + 1
      
      If cptframes = 100
        cptframes = 0
        
        If IsImage(1 + currentframe)
          ResizeImage(1 + currentframe, 128, 128, #PB_Image_Raw)
          
          StartDrawing(CanvasOutput(1))
          DrawingMode(#PB_2DDrawing_Default)
          Box(0, 0, 256, 256, RGB(0, 0, 0))
          DrawImage(ImageID(1 + currentframe), 0, 0)
          StopDrawing()
          
          ResizeImage(1 + currentframe, size, size, #PB_Image_Raw)
          
          currentframe + 1
          
          If currentframe > frames: currentframe = 1 : EndIf
        EndIf
      EndIf
    EndIf
    
    Delay(1)

  Until ev = #PB_Event_CloseWindow
  
  ; close the window
  CloseWindow(0)
Else
  ; error message
  MessageRequester("Error", "Can't open window !", #PB_MessageRequester_Error)
EndIf

; end program
End

Procedure LoadSpr(file$)
  If ReadFile(1, file$)
    palcount = ReadByte(1)
    frames = ReadByte(1)
    size = ReadByte(1)
    
    For f = 1 To frames
      StartDrawing(CanvasOutput(1))
      DrawingMode(#PB_2DDrawing_AllChannels)
      Box(0, 0, 256, 256, RGBA(0, 0, 0, 255))
      
      For y = 0 To size - 1
        For x = 0 To size - 1
          c.l = pal(ReadByte(1))          
          c = RGBA(Round(Red(c) / $55, #PB_Round_Down) * $55, Round(Green(c) / $55, #PB_Round_Down) * $55, Round(Blue(c) / $55, #PB_Round_Down) * $55, 255)
          
          Plot(x, y, c)
        Next
      Next
      
      GrabDrawingImage(f + 1, 0, 0, size, size)
      StopDrawing()
    Next
    
    CloseFile(1)
  Else
    MessageRequester("Error", "Can't find screen file !", #PB_MessageRequester_Error)
  EndIf
EndProcedure

Procedure LoadPalette(file$)
  If ReadFile(1, file$)
    tp$ = ReadString(1)
    
    If tp$ <> "JASC-PAL"
      MessageRequester("Error", "Can't recognise palette file !", #PB_MessageRequester_Error)
    Else
      ver$ = ReadString(1)
      
      If ver$ <> "0100"
        MessageRequester("Error", "Can't recognise palette file !", #PB_MessageRequester_Error)
      Else
        palcount = Val(ReadString(1))
        newpalcount = palcount
        
        If newpalcount = 1
          newpalcount = 2
        ElseIf newpalcount = 3
          newpalcount = 4
        ElseIf newpalcount > 4 And newpalcount < 16
          newpalcount = 16
        ElseIf newpalcount > 16 And newpalcount < 64
          newpalcount = 64
        ElseIf newpalcount = 2 Or newpalcount = 4 Or newpalcount = 16 Or newpalcount = 64
          ; no changes  
        Else
          MessageRequester("Error", "Too much colors in the palette !", #PB_MessageRequester_Error)
        EndIf
        
        For i = 0 To newpalcount - 1
          pal(i) = RGBA(0, 0, 0, 255)
          
          If i < palcount
            c$ = ReadString(1)
            pal(i) = RGBA(Val(StringField(c$, 1, " ")), Val(StringField(c$, 2, " ")), Val(StringField(c$, 3, " ")), 255)
          EndIf
        Next
        
        palcount = newpalcount
      EndIf
    EndIf   
    
    CloseFile(1)
  Else
    MessageRequester("Error", "Can't find palette file !", #PB_MessageRequester_Error)
  EndIf
EndProcedure

; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 19
; Folding = -
; EnableXP
; DPIAware
; Executable = sprviewer.exe