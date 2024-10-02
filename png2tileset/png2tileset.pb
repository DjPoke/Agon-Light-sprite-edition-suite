; png2tileset (for AgonLight)
;
; by B.Vignoli
; MIT 2024
;

; decoders
UsePNGImageDecoder()

; declarations
Declare LoadPalette(file$)
Declare ApplyPalette(file$)

Global Dim pal.l(63)
Global palcount.a= 0
Global newpalcount.a = 0

Global size.a = 0
Global tsize.a = 0

Global version$ = "1.0"

; create the window
If OpenWindow(0, 0, 0, 512, 512, "png2tileset (v" + version$ + ")",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
  ; create the menu
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "&Load PNG" + Chr(9) + "Ctrl+O")
    MenuItem(2, "&Load Palette" + Chr(9) + "Ctrl+P")
    MenuItem(3, "&Save Tileset" + Chr(9) + "Ctrl+S")
  EndIf
  
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_O, 1)
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_P, 2)
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_S, 3)
  
  ; check 64 colors
  SetMenuItemState(0, 11, #True)
  SetMenuItemState(0, 12, #False)
  SetMenuItemState(0, 13, #False)
  SetMenuItemState(0, 14, #False)
  
  ; create canvas gadget
  CanvasGadget(1, 0, 0, 512, 512)
  
  StartDrawing(CanvasOutput(1))
  DrawingMode(#PB_2DDrawing_Default)
  Box(0, 0, 512, 512, RGB(0, 0, 0))
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
              For i = 1 To 2
                If IsImage(i)
                  FreeImage(i)
                EndIf
              Next
              
              LoadImage(1, file$)
              
              If ImageWidth(1) = ImageHeight(1)
                size = Val(InputRequester("Tiles width","Input Tiles width","8"))
                tsize = ImageWidth(1) / size
                
                If tsize * size = ImageWidth(1)
                  CopyImage(1, 2)
                  ResizeImage(2, 512, 512, #PB_Image_Raw)
                  
                  StartDrawing(CanvasOutput(1))
                  DrawingMode(#PB_2DDrawing_Default)
                  Box(0, 0, 512, 512, RGB(0, 0, 0))
                  DrawImage(ImageID(2), 0, 0)
                  StopDrawing()
                Else
                  MessageRequester("Info", "Tilesets must be a multiple of 2 pixels !", #PB_MessageRequester_Info)
                EndIf
              EndIf
            EndIf
          Case 2
            ; request for a file name
            file$ = OpenFileRequester("Choose a Palette file to load", "", "PAL File|*.pal", 0)
            
            ; open the pal file
            If file$ <> ""
              LoadPalette(file$)
            EndIf
          Case 3
            ; convert the image and save it
            If IsImage(1) And palcount > 0
              file$ = SaveFileRequester("Choose where to save the sprite file", "", "TIL File|*.til", 0)
              
              If file$ <> ""
                If LCase(GetExtensionPart(file$)) <> "til"
                  file$ = file$ + ".til"
                EndIf
                
                ApplyPalette(file$)
                
                MessageRequester("Info", "Ok !", #PB_MessageRequester_Info)
              EndIf
            Else
              MessageRequester("Info", "Load an image an its palette first !", #PB_MessageRequester_Info)
            EndIf
        EndSelect
    EndSelect
    
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

; apply palette to frames
Procedure ApplyPalette(file$)
  If CreateFile(1, file$)
    ; write colors count
    WriteByte(1, palcount)
    
    ; write number of tiles
    WriteByte(1, tsize * tsize)
    
    ; write size of each tile
    WriteByte(1, size)
    
    ; apply palette to frames
    StartDrawing(CanvasOutput(1))
    DrawingMode(#PB_2DDrawing_AllChannels)
    Box(0, 0, 512, 512, RGBA(0, 0, 0, 255))
    DrawImage(ImageID(1), 0, 0)
    
    For ty.a = 0 To tsize - 1
      For tx.a = 0 To tsize - 1
        For y.a = 0 To size - 1
          For x.a = 0 To size - 1
            c.l = Point(tx * size + x, ty * size + y)
            c = RGBA(Red(c), Green(c), Blue(c), 255)
            
            flag = #False
            
            For i = 0 To palcount - 1
              If c = pal(i)
                flag = #True
                
                WriteByte(1, i)
                
                Break
              EndIf
            Next
            
            If flag = #False
              MessageRequester("Error", "Color not found from palette to image !", #PB_MessageRequester_Error)
              
              StopDrawing()
              
              Break(4)
            EndIf
          Next
        Next
      Next
    Next
            
    StopDrawing()
    CloseFile(1)
    
    StartDrawing(CanvasOutput(1))
    DrawingMode(#PB_2DDrawing_Default)
    Box(0, 0, 512, 512, RGB(0, 0, 0))
    DrawImage(ImageID(2), 0, 0)
    StopDrawing()    
  EndIf
EndProcedure

; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 191
; FirstLine = 185
; Folding = -
; EnableXP
; Executable = png2tileset.exe