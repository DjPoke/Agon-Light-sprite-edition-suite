; png2scn (for AgonLight)
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

; create the window
If OpenWindow(0, 0, 0, 1024, 768, "png2scn (v3)",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
  ; create the menu
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "&Load PNG" + Chr(9) + "Ctrl+O")
    MenuItem(2, "&Load Palette" + Chr(9) + "Ctrl+P")
    MenuItem(3, "&Save SCN" + Chr(9) + "Ctrl+S")
    MenuTitle("Colors")
    MenuItem(11, "64 colors")
    MenuItem(12, "16 colors")
    MenuItem(13, "4 colors")
    MenuItem(14, "2 colors")
  EndIf
  
  ; check 64 colors
  SetMenuItemState(0, 11, #True)
  SetMenuItemState(0, 12, #False)
  SetMenuItemState(0, 13, #False)
  SetMenuItemState(0, 14, #False)
  
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
            file$ = OpenFileRequester("Choose a PNG file to load", "", "PNG File|*.PNG", 0)
            
            ; open the png file
            If file$ <> ""
              LoadImage(1, file$)
              
              ; draw it to the window
              If ImageWidth(1) <= 1024 And ImageHeight(1) <= 768
                ResizeGadget(1, 0, 0, ImageWidth(1), ImageHeight(1))
                
                StartDrawing(CanvasOutput(1))
                ; grey paper
                DrawingMode(#PB_2DDrawing_Default)
                Box(0, 0, ImageWidth(1), ImageHeight(1), RGB(128, 128, 128))
                
                ; draw image
                DrawingMode(#PB_2DDrawing_AlphaBlend)
                DrawImage(ImageID(1), 0, 0)
                StopDrawing()
              EndIf
            EndIf
          Case 2
            ; request for a file name
            file$ = OpenFileRequester("Choose a PAL file to load", "", "PAL File|*.PAL", 0)
            
            ; open the pal file
            If file$ <> ""
            EndIf
          Case 3
            ; convert the image and save it
            If IsImage(1)
              file$ = SaveFileRequester("Choose where to save the screen file", "", "SCN File|*.scn", 0)
              
              If file$ <> ""
                If LCase(GetExtensionPart(file$)) <> "scn"
                  file$ = file$ + ".scn"
                EndIf
                
                ConvertPNG(file$)
                
                MessageRequester("Info", "Ok !", #PB_MessageRequester_Info)
              EndIf
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
  ; apply palette to image
EndProcedure

; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 163
; FirstLine = 130
; Folding = -
; EnableXP
; UseIcon = icons\png2scn.ico
; Executable = png2scn.exe