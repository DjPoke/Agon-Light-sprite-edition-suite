; png2scn (for AgonLight)
;
; by B.Vignoli
; MIT 2023-2024
;

#NOT_ATTRIBUED = 0
#DIFFERENT = 1
#SAME2 = 2
#SAMEMORE = 3
#DONE = 4

; decoders
UsePNGImageDecoder()

; declarations
Declare LoadPalette(file$)
Declare ApplyPalette(file$)
Declare ApplyPaletteAndCrunch(file$)
Declare.l CountColors()
Declare.l FindMode(width.l, height.l, pcount.l)

Global Dim dat.a(0)
Global Dim pal.l(63)
Global palcount.l = 0

Global version$ ="3.0"

; create the window
If OpenWindow(0, 0, 0, 1024, 768, "png2scn (v" + version$ + ")",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
  ; create the menu
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "&Load PNG" + Chr(9) + "Ctrl+O")
    MenuItem(2, "&Load Palette" + Chr(9) + "Ctrl+P")
    MenuItem(3, "&Save (raw) Screen" + Chr(9) + "Ctrl+S")
    MenuItem(4, "&Save (crunched) Screen" + Chr(9) + "Ctrl+C")
  EndIf
  
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_O, 1)
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_P, 2)
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_S, 3)
  AddKeyboardShortcut(0, #PB_Shortcut_Control + #PB_Shortcut_C, 4)
  
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
            file$ = OpenFileRequester("Choose a PNG file to load", "", "PNG File|*.png", 0)
            
            ; open the png file
            If file$ <> ""
              LoadImage(1, file$)
              
              ; draw it to the window
              If ImageWidth(1) <= 1024 And ImageHeight(1) <= 768
                ResizeGadget(1, 0, 0, ImageWidth(1), ImageHeight(1))
                
                StartDrawing(CanvasOutput(1))
                ; grey paper
                DrawingMode(#PB_2DDrawing_AllChannels)
                Box(0, 0, ImageWidth(1), ImageHeight(1), RGBA(128, 128, 128, 255))
                
                ; draw image
                DrawingMode(#PB_2DDrawing_AlphaBlend)
                DrawImage(ImageID(1), 0, 0)
                StopDrawing()
              EndIf
            EndIf
          Case 2
            ; request for a file name
            file$ = OpenFileRequester("Choose a PAL file to load", "", "PAL File|*.pal", 0)
            
            ; open the pal file
            If file$ <> ""
              LoadPalette(file$)
            EndIf
          Case 3
            ; apply the palette to the image and save it
            If IsImage(1) And palcount > 0
              file$ = SaveFileRequester("Choose where to save the screen file", "", "SCN File|*.scn", 0)
              
              If file$ <> ""
                If LCase(GetExtensionPart(file$)) <> "scn"
                  file$ = file$ + ".scn"
                EndIf
                
                ApplyPalette(file$)
                
                MessageRequester("Info", "Ok !", #PB_MessageRequester_Info)
              EndIf
            Else
              MessageRequester("Info", "Load an image an its palette first !", #PB_MessageRequester_Info)
            EndIf
          Case 4
            ; apply the palette to the image, crunch it and save it
            If IsImage(1) And palcount > 0
              file$ = SaveFileRequester("Choose where to save the screen file", "", "SCN File|*.scn", 0)
              
              If file$ <> ""
                If LCase(GetExtensionPart(file$)) <> "scn"
                  file$ = file$ + ".scn"
                EndIf
                
                ApplyPaletteAndCrunch(file$)
                
                MessageRequester("Info", "Ok !", #PB_MessageRequester_Info)
              EndIf
            Else
              MessageRequester("Info", "Load an image an its palette first !", #PB_MessageRequester_Info)
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

Procedure ApplyPalette(file$)
  ; palette loaded ?
  If CountColors() > palcount
    MessageRequester("Error", "Too much colors in the image !", #PB_MessageRequester_Error)
  Else
    If CreateFile(1, file$)
      ; find mode and save it
      mode.b = FindMode(ImageWidth(1), ImageHeight(1), palcount)
      
      If mode = 24
        MessageRequester("Error", "Not corresponding to a graphic mode of the AgonLight !", #PB_MessageRequester_Error)
      Else
        ; write mode
        WriteByte(1, mode)
        
        ; write RGB palette
        For i = 0 To palcount - 1
          WriteByte(1, Red(pal(i)))
          WriteByte(1, Green(pal(i)))
          WriteByte(1, Blue(pal(i)))
        Next
        
        ; raw file: 0
        WriteByte(1, 0)
        
        ; apply palette to image
        StartDrawing(CanvasOutput(1))
        DrawingMode(#PB_2DDrawing_AllChannels)
        
        For y.l = 0 To ImageHeight(1) - 1
          For x.l = 0 To ImageWidth(1) - 1
            c.l = Point(x, y)
            c = RGBA(Red(c), Green(c), Blue(c), 255)
            
            flag = #False
            
            For i = 0 To palcount - 1
              If c = pal(i)
                flag = #True
                
                WriteByte(1, i)
              EndIf
            Next
            
            If flag = #False
              MessageRequester("Error", "Color not found from palette to image !", #PB_MessageRequester_Error)
              Break(2)
            EndIf
          Next
        Next
        
        StopDrawing()
      EndIf
      
      CloseFile(1)
    Else
      MessageRequester("Error", "Can't create screen file !", #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure ApplyPaletteAndCrunch(file$)
  ; palette loaded ?
  If CountColors() > palcount
    MessageRequester("Error", "Too much colors in the image !", #PB_MessageRequester_Error)
  ElseIf CreateFile(1, file$)
    ; find mode and save it
    mode.b = FindMode(ImageWidth(1), ImageHeight(1), palcount)
    
    If mode = 24
      MessageRequester("Error", "Not corresponding to a graphic mode of the AgonLight !", #PB_MessageRequester_Error)
    Else
      ; write mode
      WriteByte(1, mode)
      
      ; write RGB palette
      For i = 0 To palcount - 1
        WriteByte(1, Red(pal(i)))
        WriteByte(1, Green(pal(i)))
        WriteByte(1, Blue(pal(i)))
      Next
      
      ; crunched file: 1
      WriteByte(1, 1)
      
      ; apply palette to image
      StartDrawing(CanvasOutput(1))
      DrawingMode(#PB_2DDrawing_AllChannels)
      
      ReDim dat(ImageWidth(1) * ImageHeight(1))
      
      cpt.l = 0
      
      For y.l = 0 To ImageHeight(1) - 1
        For x.l = 0 To ImageWidth(1) - 1
          c.l = Point(x, y)
          c = RGBA(Red(c), Green(c), Blue(c), 255)
          
          flag = #False
          
          For i = 0 To palcount - 1
            If c = pal(i)
              flag = #True
              
              dat(cpt) = i
              cpt + 1
            EndIf
          Next
          
          If flag = #False
            MessageRequester("Error", "Color not found from palette to image !", #PB_MessageRequester_Error)
            Break(2)
          EndIf
        Next
      Next
      
      StopDrawing()
      
      ;
      ProgressBarGadget(2, 256, 376, 512, 16, 0, 100)
      
      ; TODO: remove me !
      ReDim dat(16)
      
      For i = 0 To 15
        dat(i) = 4
      Next
      ; for to test...

      ; crunch data
      cpt1.l = 0
      cpt2.l = 0
      current.a = dat(cpt1)
      cmd.l = #NOT_ATTRIBUED
      
      ; while not done...
      While cmd <> #DONE
        ; prepare to read next value
        cpt2 + 1
        
        ; not EOF ? continue
        If cpt2 < ArraySize(dat())
          Select cmd
            Case #NOT_ATTRIBUED
              ; next data is different ?
              If dat(cpt2) <> current
                ; change command to DIFFERENT
                cmd = #DIFFERENT
                ; else  
              Else
                ; change command to SAME2
                cmd = #SAME2
              EndIf              
            Case #DIFFERENT
              ; next data is different ?
              If dat(cpt2) <> current
                ; different data count = 254 ?
                If cpt2 - cpt1 + 1 = 254
                  ; write crunched data
                  WriteByte(1, 254)
                  
                  For i = cpt1 To cpt2
                    WriteByte(1, dat(i))
                    Debug(Hex(dat(i)))
                  Next
                 
                  cpt1 = cpt2 + 1
                  current = dat(cpt1)
                  
                  cmd = #NOT_ATTRIBUED
                EndIf
              ; next data is same ?
              Else
                ; pointer go back
                cpt2 - 2
                
                ; if there is only one data different...
                If cpt1 = cpt2
                  ; write data count and data
                  WriteByte(1, 1)
                  WriteByte(1, current)
                  
                  cpt1 = cpt2 + 1
                  current = dat(cpt1)
                  cmd = #NOT_ATTRIBUED                  
                ; else, if there are lot of differents data
                Else
                  ; write data count and data
                  WriteByte(1, cpt2 - cpt1)
                  
                  For i = cpt1 To cpt2 - 1
                    WriteByte(1, dat(i))
                  Next
                  
                  cpt1 = cpt2 + 1
                  current = dat(cpt1)
                  cmd = #NOT_ATTRIBUED
                EndIf
              EndIf
            Case #SAME2
              ; if there are more than two same data...
              If dat(cpt2) = current
                ; change command to SAME MORE
                cmd = #SAMEMORE
                ; else...
              Else
                ; write byte 255, and the byte value
                WriteByte(1, 255)                    
                WriteByte(1, current)
                
                cpt1 = cpt2
                current = dat(cpt1)
                cmd = #NOT_ATTRIBUED
              EndIf
            Case #SAMEMORE
              ; next data is same ?
              If dat(cpt2) = current
                ; we have 256 bytes the same ?
                If cpt2 - cpt1 + 1 = 256
                  ; write byte 0 two times, and the byte value
                  WriteByte(1, 0)
                  WriteByte(1, 0)
                  WriteByte(1, current)                  
                
                  cpt1 = cpt2 + 1
                  current = dat(cpt1)
                  cmd = #NOT_ATTRIBUED
                EndIf
              ; next data is different ?
              Else
                cpt2 - 1
                
                ; write byte 0, bytes count, and the byte value
                WriteByte(1, 0)
                WriteByte(1, cpt2 - cpt1 + 1)
                WriteByte(1, current)
                
                cpt1 = cpt2 + 1
                current = dat(cpt1)
                cmd = #NOT_ATTRIBUED
              EndIf
          EndSelect
        ; EOF ?
        Else
          Select cmd
            Case #NOT_ATTRIBUED
              ; write 1 byte, and the last byte value
              WriteByte(1, 1)
              WriteByte(1, current)
            Case #DIFFERENT
              ; write number of different bytes, and the last byte values
              WriteByte(1, cpt2 - cpt1)
              
              For i = cpt1 To cpt2 - 1
                WriteByte(1, dat(i))
              Next
            Case #SAME2
              WriteByte(1, 255)
              WriteByte(1, current)
            Case #SAMEMORE
              WriteByte(1, 0)
              WriteByte(1, Mod(cpt2 - cpt1 + 1, 256))                
              WriteByte(1, current)
          EndSelect        
          
          cmd = #DONE
        EndIf
      Wend
    EndIf
    
    FreeGadget(2)

    CloseFile(1)
  Else
    MessageRequester("Error", "Can't create screen file !", #PB_MessageRequester_Error)
  EndIf
EndProcedure

Procedure.l CountColors()
EndProcedure

Procedure.l FindMode(width.l, height.l, pcount.l)
  Restore Modes
  For i = 0 To 23
    Read.l w
    Read.l h
    Read.l pc
    
    If width = w And height = h And pcount = pc
      ProcedureReturn i
    EndIf
  Next
  
  ProcedureReturn 24
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
; CursorPosition = 315
; FirstLine = 302
; Folding = -
; EnableXP
; UseIcon = icons\png2scn.ico
; Executable = png2scn.exe