; sprviewer (for AgonLight)
;
; by B.Vignoli
; MIT 2024
;

; declarations
Declare LoadSpr(file$)

Global Dim pal.l(63)
Global palcount.l = 0

Global version$ = "1.0"

; create the window
If OpenWindow(0, 0, 0, 256, 64, "sprviewer (v" + version$ + ")",#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_MinimizeGadget)
  ; create the menu
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "&Load SPR" + Chr(9) + "Ctrl+O")
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
            file$ = OpenFileRequester("Choose a Sprite file to load", "", "SPR File|*.spr", 0)
            
            ; open the png file
            If file$ <> ""
              LoadSpr(file$)
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

Procedure LoadSpr(file$)
  If ReadFile(1, file$)
    CloseFile(1)
  Else
    MessageRequester("Error", "Can't find screen file !", #PB_MessageRequester_Error)
  EndIf
EndProcedure

; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 63
; FirstLine = 37
; Folding = -
; EnableXP
; DPIAware
; Executable = sprviewer.exe