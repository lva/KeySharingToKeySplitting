#pragma compile(Out, KeySharingToKeySplitting.exe)
#pragma compile(ProductName, KeySharingToKeySplitting)
#pragma compile(ProductVersion, 1.0)
#pragma compile(Icon, key_icon.ico)

#include <GuiConstants.au3>
#include <MsgBoxConstants.au3>
#include <String.au3>

; Two libraries from the AutoIt Machine Code Algorithm Collection
; See https://www.autoitscript.com/forum/topic/121985-autoit-machine-code-algorithm-collection/
#include "AES.au3"
#Include "DES.au3"

Opt("GUIOnEventMode", 1)
Opt("GUICloseOnESC", 0)
Opt("MustDeclareVars", 1)
GUIRegisterMsg($WM_COMMAND, "MY_WM_COMMAND")

; Global variables containing GUI elements.
Global $hInpComponent, $hLblKCV, $hGUI, $hBtnOk, $hBtnCancel, $hInpKCV
Global $hComboKeyType, $hBtnContinue, $hUpDownComponents, $hBtnShowNextComponent

; Defines the key type of the cryptographic key.
; Currently supported: AES-128, 3DES-128, 3DES-192
Global $sKeyType = "3DES-192"
; Defined the length of a key of the select key type.
Global $iKeyCompLen = (192 / 8) * 2
; Contains an initial empty key.
Global $bCombinedKey = Binary("0x" & _StringRepeat("0", $iKeyCompLen))
; Contains the number of components and an iterator over the number of components collected/displayed.
Global $iComponents, $iCurrentComponent = 0

; Start the application by asking for the key type and the number of components.
askAttributes()

; Keep running until the program finishes or the user click 'Cancel'.
While 1
WEnd

; Step 1: show a form that asks to select the key type and the number of components.
Func askAttributes()
   $hGUI = GUICreate("Key sharing to key splitting", 300, 100)
   GUICtrlCreateLabel("Select key type:", 10, 10, 80, 15)
   $hComboKeyType = GUICtrlCreateCombo("", 100, 10, 100, 20)
   GUICtrlSetData($hComboKeyType, "AES 128-bit|3DES 128-bit|3DES 192-bit", "")
   GUICtrlCreateLabel("Number of components to enter:", 10, 35, 165, 25)
   $hUpDownComponents = GUICtrlCreateInput("2", 175, 35, 40, 20)
   GUICtrlCreateUpdown($hUpDownComponents)
   $hBtnContinue = GUICtrlCreateButton("Continue", 10, 60, 75, 25, $BS_DEFPUSHBUTTON)
   GUICtrlSetState($hBtnContinue, $GUI_DISABLE)
   $hBtnCancel = GUICtrlCreateButton("Cancel", 95, 60, 75, 25)
   GUISetState(@SW_SHOW, $hGUI)
EndFunc

; Step 2: store the key type and the number of components in global variables.
Func processAttributes()
   ; Check the selected key type and set the internally used key type, key length, and initial zero key.
   Switch GUICtrlRead($hComboKeyType)
   Case "AES 128-bit"
	  $sKeyType = "AES-128"
	  $iKeyCompLen = (128 / 8) * 2
	  $bCombinedKey = Binary("0x" & _StringRepeat("0", $iKeyCompLen))
   Case "3DES 128-bit"
	  $sKeyType = "3DES-128"
	  $iKeyCompLen = (128 / 8) * 2
	  $bCombinedKey = Binary("0x" & _StringRepeat("0", $iKeyCompLen))
   Case "3DES 192-bit"
	  $sKeyType = "3DES-192"
	  $iKeyCompLen = (192 / 8) * 2
	  $bCombinedKey = Binary("0x" & _StringRepeat("0", $iKeyCompLen))
   EndSwitch

   ; Hide the form that asks for the attributes.
   GUISetState(@SW_HIDE, $hGUI)

   ; Store the number of components.
   $iComponents = Int(GUICtrlRead($hUpDownComponents))

   ; Ask for all components.
   askNextComponent()
EndFunc

; Step 3: control function to gather all input components:
;   - If not all components have been entered, ask for the next component.
;   - If all components have been entered, show the KCV of the combined key and start displaying the splitted parts.
Func askNextComponent()
   If $iCurrentComponent < $iComponents Then
	  $iCurrentComponent = $iCurrentComponent + 1
	  askComponent($iCurrentComponent)
   Else
	  showCombinedKcv()
	  showNextComponent()
   EndIf
EndFunc

; Step 3a: show a form that allows to enter a component.
Func askComponent($iComponent)
   $hGUI = GUICreate("Ready to accept component " & $iComponent, 430, 100)
   GUICtrlCreateLabel("Enter HEX component (0-9, A-F)", 10, 10, 310, 15)
   $hInpComponent = GUICtrlCreateInput ("", 10, 35, 350, 20)
   $hLblKCV = GUICtrlCreateLabel("KCV:", 370, 10, 110, 15)
   $hInpKCV = GUICtrlCreateInput ("", 370, 35, 50, 20, $ES_READONLY)
   $hBtnOk = GUICtrlCreateButton("OK", 160, 60, 50, 25, $BS_DEFPUSHBUTTON)
   GUICtrlSetState($hBtnOk, $GUI_DISABLE)
   $hBtnCancel = GUICtrlCreateButton("Cancel", 220, 60, 50, 25)

   GUISetState(@SW_SHOW, $hGUI)
EndFunc

; Step 3b: Shows the KCV of the combined key.
Func showCombinedKcv()
   MsgBox(0, "KCV of combined key", "The KCV of the combined key is: " & calculateKCV($bCombinedKey) & @CRLF & @CRLF & "Ready to display splitted components...")
   ; Set counter of shown components to zero.
   $iCurrentComponent = 0
EndFunc

; Step 4: control function to display all output components:
;   - If not all components have been displayed, display the next component.
;   - If all components have been display, exit the application.
Func showNextComponent()
   If $iCurrentComponent < $iComponents Then
	  $iCurrentComponent = $iCurrentComponent + 1
	  showComponent($iCurrentComponent)
   Else
	  Exit
   EndIf
EndFunc

; Step 4a: show a form that displays a splitted component.
Func showComponent($iComponent)
   ; Calculate the length of the component.
   Local $iSplitComponentLen = Floor(BinaryLen($bCombinedKey) / $iComponents)
   ; Calculate the location of the first byte of the component.
   Local $iFirst = (($iComponent - 1) * $iSplitComponentLen) + 1
   ; When showing the last component, show all remaining bytes.
   ; Must be done when the combined key cannot be split in components of equal length, for example when splitting a 128-bit key in 3 components.
   If $iComponent = $iComponents Then
	  $iSplitComponentLen = BinaryLen($bCombinedKey) - (($iComponent - 1) *  $iSplitComponentLen)
   EndIf
   ; Extract the component from the combined key.
   Local $sComponent = BinaryMid($bCombinedKey, $iFirst, $iSplitComponentLen)
   ; Remove the "0x" from the beginning of the component.
   $sComponent = StringRight($sComponent, StringLen($sComponent) - 2)

   ; Show a messagebox alerting that the next component will be displayed.
   MsgBox(0, "Show component", "Ready to show component " & $iComponent)

   ; Show a form that displays the component.
   $hGUI = GUICreate("Ready to show component " & $iComponent, 430, 100)
   GUICtrlCreateLabel("HEX component (0-9, A-F)", 10, 10, 310, 15)
   GUICtrlCreateInput ($sComponent, 10, 35, 350, 20, $ES_READONLY)
   $hBtnShowNextComponent = GUICtrlCreateButton("Continue", 160, 60, 50, 25, $BS_DEFPUSHBUTTON)
   $hBtnCancel = GUICtrlCreateButton("Cancel", 220, 60, 50, 25)
   GUISetState(@SW_SHOW, $hGUI)
EndFunc

; Function that is executed when the key type ComboBox is changed.
; Only when a valid key type is selected, the "Continue" button is enabled.
Func _GUI_hComboKeyType_Changed()
   Switch GUICtrlRead($hComboKeyType)
   Case "AES 128-bit", "3DES 128-bit", "3DES 192-bit"
	  GUICtrlSetState($hBtnContinue, $GUI_ENABLE)
   Case Else
	  GUICtrlSetState($hBtnContinue, $GUI_DISABLE)
   EndSwitch
EndFunc

; Function that is executed when key custodians are typing their key in the form.
Func _GUI_Component_Changed()
   ; Remove all non-hexadecimal digits and limit the length to the key size length.
   GUICtrlSetData($hInpComponent, StringLeft(StringRegExpReplace(GUICtrlRead($hInpComponent), "[^[:xdigit:]]", ""), $iKeyCompLen))
   ; Update the KCV since the typed component has changed.
   updateKCV()
EndFunc

; Function that updates the KCV on the component input form.
; It only shows the KCV when the length of the input is equal to the expected key length.
Func updateKCV()
   If StringLen(GUICtrlRead($hInpComponent)) = $iKeyCompLen Then
	  GUICtrlSetData($hInpKCV, calculateKCV(Binary("0x" & GUICtrlRead($hInpComponent))))
	  GUICtrlSetState($hBtnOk, $GUI_ENABLE)
   Else
	  GUICtrlSetData($hInpKCV, "")
	  GUICtrlSetState($hBtnOk, $GUI_DISABLE)
   EndIf
EndFunc

; Function that does a binary XOR of two keys of equal length.
Func binaryXorKeys($bKey1, $bKey2)
   Local $bFinalkey = "0x"

   For $i = 1 To BinaryLen($bKey1)
	  $bFinalkey = $bFinalkey & Hex(BitXOR(BinaryMid($bKey1, $i, 1), BinaryMid($bKey2, $i, 1)), 2)
   Next

   Return Binary($bFinalkey)
EndFunc

; Function that calculates the KCV (Key Check Value) of a key.
; This is done by encrypting a null string using the selected algorithm with the key.
Func calculateKCV($bKey)
   Local $sNullData = Binary('0x00')

   Switch ($sKeyType)
   Case "AES-128"
	  Local $bEncrypted = _AesEncryptECB(_AesEncryptKey($bKey), $sNullData)
	  Return StringRight(BinaryMid($bEncrypted, 1, 3), 6)
   Case "3DES-128"
	  ; First make a 3DES key from the 2DES key.
	  $bKey = $bKey & BinaryMid($bKey, 1, 8)
	  Local $bEncrypted = _3DesCryptECB(_3DesEncryptKey($bKey), $sNullData)
	  Return StringRight(BinaryMid($bEncrypted, 1, 3), 6)
   Case "3DES-192"
	  Local $bEncrypted = _3DesCryptECB(_3DesEncryptKey($bKey), $sNullData)
	  Return StringRight(BinaryMid($bEncrypted, 1, 3), 6)
   EndSwitch
EndFunc

; React on a button click or GUI control change.
Func MY_WM_COMMAND($hWnd, $msg, $wParam, $lParam)
   Local $nNotifyCode = BitShift($wParam, 16)
   Local $nID = BitAND($wParam, 0xFFFF)
   Local $hCtrl = $lParam

   Switch $nID
   Case $hInpComponent
	  _GUI_Component_Changed()
   Case $hComboKeyType
	  _GUI_hComboKeyType_Changed()
   Case $hBtnShowNextComponent
	  GUISetState(@SW_HIDE, $hGUI)
	  showNextComponent()
   ; The OK button on the for that asks to enter the input components.
   Case $hBtnOk
	  ; XOR the entered key with the combined key.
	  $bCombinedKey = binaryXorKeys($bCombinedKey, Binary("0x" & GUICtrlRead($hInpComponent)))
	  ; Hide the GUI form.
	  GUISetState(@SW_HIDE, $hGUI)
	  ; Ask for the next component.
	  askNextComponent()
   ; The cancel button is clicked. This button can appear on all forms.
   Case $hBtnCancel
	  Local $iRet = MsgBox($MB_YESNO + $MB_ICONQUESTION, "Cancel?", "Are you sure you want to exit this application?")
	  If $iRet = $IDYES Then
		 Exit
	  EndIf
   Case $hBtnContinue
	  processAttributes()
   EndSwitch

   ; Proceed the default Autoit3 internal message commands.
   ; You also can complete let the line out.
   ; !!! But only 'Return' (without any value) will not proceed
   ; the default Autoit3-message in the future !!!
   Return $GUI_RUNDEFMSG
EndFunc   ;==>MY_WM_COMMAND