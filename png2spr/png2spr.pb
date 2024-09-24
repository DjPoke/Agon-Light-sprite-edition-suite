; png2spr (for AgonLight)
;
; by B.Vignoli
; MIT 2023-2024
;

; decoders
UsePNGImageDecoder()

; declarations
Declare LoadPalette(file$)
Declare ConvertPNG(file$)

Global Dim pal.l(63)
Global palcount.l = 0
Global newpalcount.l = 0

Global frames.l = 0
Global currentframe.l = 0
Global cptframes.l = 0

Global version$ = "3.0"

; create the window
If OpenWindow(0, 0, 0, 256, 256, "png2spr (v" + version$ + ")",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
  ; create the menu
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "&Load PNG" + Chr(9) + "Ctrl+O")
    MenuItem(2, "&Load Palette" + Chr(9) + "Ctrl+P")
    MenuItem(3, "&Save Sprite" + Chr(9) + "Ctrl+S")
  EndIf
  
  ; check 64 colors
  SetMenuItemState(0, 11, #True)
  SetMenuItemState(0, 12, #False)
  SetMenuItemState(0, 13, #False)
  SetMenuItemState(0, 14, #False)
  
  ; create canvas gadget
  CanvasGadget(1, 0, 0, 256, 256)
  
  StartDrawing(CanvasOutput(1))
  DrawingMode(#PB_2DDrawing_Default)
  Box(0, 0, 256, 256, RGB(0, 0, 0))
  StopDrawing()
  
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
            file$ = OpenFileRequester("Choose a PNG file to load", "", "PNG File|*.PNG", 0)
            
            ; open the png file
            If file$ <> ""
              LoadImage(1, file$)
              
              If ImageWidth(1) = ImageHeight(1)
                CopyImage(1, 2)
                
                StartDrawing(CanvasOutput(1))
                DrawingMode(#PB_2DDrawing_Default)
                DrawImage(ImageID(2), 0, 0)
                StopDrawing()
                
                frames = 1
                currentframe = 1
                cptframes = 0
              ElseIf ImageWidth(1) > ImageHeight(1)
                div1.d = ImageWidth(1) / ImageHeight(1)
                div2.l = Round(div1, #PB_Round_Nearest)
                frames = 0
                currentframe = 1
                cptframes = 0
                
                If div1 = div2
                  For i = 1 To div2
                    GrabImage(1, 2 + frames, ImageHeight(1) * (i - 1), 0, ImageHeight(1), ImageHeight(1))
                    frames + 1
                  Next                  
                Else
                  MessageRequester("Error", "Animstrip's width and height are not proportionnal !", #PB_MessageRequester_Error)
                EndIf
              ElseIf ImageWidth(1) < ImageHeight(1)
                div1.d = ImageHeight(1) / ImageWidth(1)
                div2.l = Round(div1, #PB_Round_Nearest)
                frames = 0
                currentframe = 1
                cptframes = 0
                
                If div1 = div2
                  For i = 1 To div2
                    GrabImage(1, 2 + frames, ImageWidth(1) * (i - 1), 0, ImageWidth(1), ImageWidth(1))
                    frames + 1
                  Next                  
                Else
                  MessageRequester("Error", "Animstrip's width and height are not proportionnal !", #PB_MessageRequester_Error)
                EndIf
              EndIf
            EndIf
          Case 2
            ; request for a file name
            file$ = OpenFileRequester("Choose a PAL file to load", "", "PAL File|*.PAL", 0)
            
            ; open the pal file
            If file$ <> ""
              LoadPalette(file$)
            EndIf
          Case 3
            ; convert the image and save it
            If IsImage(1)
              file$ = SaveFileRequester("Choose where to save the sprite file", "", "SPR File|*.spr", 0)
              
              If file$ <> ""
                If LCase(GetExtensionPart(file$)) <> "spr"
                  file$ = file$ + ".spr"
                EndIf
                
                ConvertPNG(file$)
                
                MessageRequester("Info", "Ok !", #PB_MessageRequester_Info)
              EndIf
            EndIf
        EndSelect
    EndSelect
    
    ; drawing animation
    If frames > 0
      cptframes + 1
      
      If cptframes = 100
        cptframes = 0
        
        ResizeImage(1 + currentframe, 128, 128, #PB_Image_Raw)
        
        StartDrawing(CanvasOutput(1))
        DrawingMode(#PB_2DDrawing_Default)
        Box(0, 0, 256, 256, RGB(0, 0, 0))
        DrawImage(ImageID(1 + currentframe), 0, 0)
        StopDrawing()
        
        ResizeImage(1 + currentframe, ImageWidth(1), ImageWidth(1), #PB_Image_Raw)
        
        currentframe + 1
        
        If currentframe > frames: currentframe = 1 : EndIf
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
            pal(i) = RGB(Val(StringField(c$, 1, " ")), Val(StringField(c$, 2, " ")), Val(StringField(c$, 3, " ")))
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

Procedure ConvertPNG(file$)
  ; apply palette to frames
  
EndProcedure

; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 154
; FirstLine = 162
; Folding = -
; EnableXP
; UseIcon = icons\png2spr.ico
; Executable = png2spr.exe