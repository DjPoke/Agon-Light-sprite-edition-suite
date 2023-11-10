; png2spr For AgonLight
;
; by B.Vignoli
; M.I.T 2023
;

; decoders
UsePNGImageDecoder()

; declarations
Declare InitPalette()
Declare ConvertPNG(f.s)

Global Dim pal.l(63)

; create the window
If OpenWindow(0, 0, 0, 300, 100, "png2spr v2 - Convert png to sprites !",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
  ; create the menu
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "&Open PNG" + Chr(9) + "Ctrl+O")
    MenuItem(2, "&Save SPR" + Chr(9) + "Ctrl+S")
  EndIf
  
  ; initialization
  InitPalette()
  
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
            file$ = OpenFileRequester("Choose a png file to load", "", "PNG File|*.png", 0)
            
            ; open the png file
            If file$ <> ""
              LoadImage(1, file$)
            EndIf
          Case 2
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
  Until ev = #PB_Event_CloseWindow
  
  ; close the window
  CloseWindow(0)
Else
  ; error message
  MessageRequester("Error", "Can't open window !", #PB_MessageRequester_Error)
EndIf

; end program
End


; procedures
Procedure ConvertPNG(f.s)
  ; request sprite width & height
  spr_width.l = Val(InputRequester("Sprite width", "Please input the sprite width:", "16"))
  spr_height.l = Val(InputRequester("Sprite height", "Please input the sprite height:", "16"))
  
  ; wrong value ?
  If spr_width < 1 Or spr_height < 1
    MessageRequester("Error", "Wrong sprite size !", #PB_MessageRequester_Error)
    End  
  EndIf
  
  spr_sizex.l = ImageWidth(1) / spr_width
  spr_sizey.l = ImageHeight(1) / spr_height
  
  If spr_width * spr_sizex <> ImageWidth(1) Or spr_height * spr_sizey <> ImageHeight(1)
    MessageRequester("Error", "Wrong PNG size !", #PB_MessageRequester_Error)
    End  
  EndIf
  
  ; create spr file
  CreateFile(1, f)
  WriteWord(1, spr_width * spr_height)
  WriteByte(1, spr_sizex)
  WriteByte(1, spr_sizey)
  
  ; get colors
  StartDrawing(ImageOutput(1))
  DrawingMode(#PB_2DDrawing_AllChannels)
  For yt = 0 To spr_sizey - 1
    For xt = 0 To spr_sizex - 1
      For y = 0 To spr_height - 1
        For x = 0 To spr_width - 1
          xc.l = (xt * spr_width) + x
          yc.l = (yt * spr_height) + y

          c1 = Point(xc, yc)
          r1 = Red(c1)
          g1 = Green(c1)
          b1 = Blue(c1)
          
          For c2.b = 0 To 63
            r2 = Red(pal(c2))
            g2 = Green(pal(c2))
            b2 = Blue(pal(c2))
            
            If r1 = r2 And g1 = g2 And b1 = b2
              Break
            EndIf
          Next
          
          ; error ?
          If c2 = 64
            MessageRequester("Error", "Wrong RGB color in the png file !", #PB_MessageRequester_Error)
            
            StopDrawing()
            CloseFile(1)
            
            End
          Else
            WriteByte(1, c2)
          EndIf
        Next
      Next
    Next
  Next
  
  StopDrawing()
  CloseFile(1)
EndProcedure

; initialize the Agon Light palette
Procedure InitPalette()
  Restore palette
  
  r.l = 0
  g.l = 0
  b.l = 0
  
  For i = 0 To 63
    Read.l r
    Read.l g
    Read.l b
    
    pal(i) = RGB(r, g, b)
  Next
EndProcedure

DataSection
  palette:
  
  Data.l $00,$00,$00
	Data.l $AA,$00,$00
	Data.l $00,$AA,$00
	Data.l $AA,$AA,$00
	Data.l $00,$00,$AA
	Data.l $AA,$00,$AA
	Data.l $00,$AA,$AA
	Data.l $AA,$AA,$AA

	Data.l $55,$55,$55
	Data.l $FF,$00,$00
	Data.l $00,$FF,$00
	Data.l $FF,$FF,$00
	Data.l $00,$00,$FF
	Data.l $FF,$00,$FF
	Data.l $00,$FF,$FF
	Data.l $FF,$FF,$FF

	Data.l $00,$00,$55
	Data.l $00,$55,$00
	Data.l $00,$55,$55
	Data.l $00,$55,$AA
	Data.l $00,$55,$FF
	Data.l $00,$AA,$55
	Data.l $00,$AA,$FF
	Data.l $00,$FF,$55

	Data.l $00,$FF,$AA
	Data.l $55,$00,$00
	Data.l $55,$00,$55
	Data.l $55,$00,$AA
	Data.l $55,$00,$FF
	Data.l $55,$55,$00
	Data.l $55,$55,$AA
	Data.l $55,$55,$FF

	Data.l $55,$AA,$00
	Data.l $55,$AA,$55
	Data.l $55,$AA,$AA
	Data.l $55,$AA,$FF
	Data.l $55,$FF,$00
	Data.l $55,$FF,$55
	Data.l $55,$FF,$AA
	Data.l $55,$FF,$FF

	Data.l $AA,$00,$55
	Data.l $AA,$00,$FF
	Data.l $AA,$55,$00
	Data.l $AA,$55,$55
	Data.l $AA,$55,$AA
	Data.l $AA,$55,$FF
	Data.l $AA,$AA,$55
	Data.l $AA,$AA,$FF

	Data.l $AA,$FF,$00
	Data.l $AA,$FF,$55
	Data.l $AA,$FF,$AA
	Data.l $AA,$FF,$FF
	Data.l $FF,$00,$55
	Data.l $FF,$00,$AA
	Data.l $FF,$55,$00
	Data.l $FF,$55,$55

	Data.l $FF,$55,$AA
	Data.l $FF,$55,$FF
	Data.l $FF,$AA,$00
	Data.l $FF,$AA,$55
	Data.l $FF,$AA,$AA
	Data.l $FF,$AA,$FF
	Data.l $FF,$FF,$55
	Data.l $FF,$FF,$AA
EndDataSection

; IDE Options = PureBasic 6.03 LTS (Windows - x64)
; CursorPosition = 16
; Folding = -
; EnableXP
; UseIcon = png2spr.ico
; Executable = png2spr v2.exe