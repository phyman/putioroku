REM /*------------------------------------------------- Settings -----
REM |  Function Settings
REM |
REM |  Purpose:
REM |      Presents the user with the various settings that may be toggled
REM |
REM |  Returns:
REM |      1 if user unlinked their device, -1 on screen close
REM *-------------------------------------------------------------------*/

function Settings() as Integer
  m.screen  = CreateObject("roListScreen")
  port      = CreateObject("roMessagePort")
  m.buttons = InitScreenButtons()

  m.screen.SetMessagePort(port)
  RefreshScreen()

  while (m.g.state.WAITING_FOR_USER_INPUT)
      msg = wait(0, port)

      if (msg.isScreenClosed()) then
        SaveChangesToRegistry()
        return -1
      end if

      if (type(msg) = "roListScreenEvent") then
        if (msg.isListItemSelected()) then
          selection = msg.GetIndex()
          if (selection <= m.buttons.count())
            m.buttons[selection].btnOnClickEvent(selection)
          end if
        end if
      end if

  end while
end function

REM /*------------------------------------------------- InitScreenButtons -----
REM |  Function InitScreenButtons
REM |
REM |  Purpose:
REM |      Creates & populates the buttons to use on the screen
REM |
REM |  Returns:
REM |      btnArr - an array of populated buttons for the screen’s use
REM *-------------------------------------------------------------------*/

Function InitScreenButtons() as Object
  ' Screen button "enums"
  btn               = CreateObject("roAssociativeArray")
  btn.SUBTITLES     = 0
  btn.DELETE        = 1
  btn.UNLINK        = 2

  ' Screen button data
  btnArr = CreateObject("roArray", btn.count(), true)

  btnArr[btn.SUBTITLES] = {
      Title:            "~ERROR~",
      HDSmallIconUrl:   "pkg:/images/subtitles.png",
      btnOnClickEvent:  toggle_subtitles,
      label_seg:        "subtitles",
      btnState:         m.subtitle_on,
      SetLabel:         set_label,
  }

  btnArr[btn.DELETE] = {
      Title:            "~ERROR~",
      HDSmallIconUrl:   "pkg:/images/unlink.png",
      btnOnClickEvent:  toggle_deletion,
      label_seg:        "file deletion",
      btnState:         m.delete_allowed,
      SetLabel:         set_label,
  }

  btnArr[btn.UNLINK] = {
      Title:            "Unlink this device",
      HDSmallIconUrl:   "pkg:/images/unlink.png",
      btnOnClickEvent:  unlink_device,
  }

  btnArr[btn.DELETE].SetLabel()
  btnArr[btn.SUBTITLES].SetLabel()

  return btnArr
End Function

Function set_label()
  btnLbl = "~ERROR~"
  if (m.btnState = "true" ) then btnLbl = "Disable " + m.label_seg
  if (m.btnState = "false" ) then btnLbl = "Enable " + m.label_seg
  if (btnLbl <> "~ERROR~")
    ?  "set_label to: " btnLbl
    m.Title = btnLbl
  end if
End Function

REM /*------------------------------------------------- toggle_subtitles -----
REM |  Function toggle_subtitles
REM |
REM |  Purpose:
REM |      Toggles the global subtitles setting and button label when selected
REM *-------------------------------------------------------------------*/

Sub toggle_subtitles(index as Integer)
  GetGlobalAA().subtitle_on = toggleSetting(m, index)
end Sub

REM /*------------------------------------------------- toggle_deletion -----
REM |  Function toggle_deletion
REM |
REM |  Purpose:
REM |      Toggles the user's permission to delete content
REM *-------------------------------------------------------------------*/

Sub toggle_deletion(index as Integer)
  GetGlobalAA().delete_allowed = toggleSetting(m, index)
end Sub

Function toggleSetting(m as Object, index as Integer) as String
  'print "~~~~ toggleSetting::m.btnState is: " m.btnState
  if (m.btnState = "true")
    m.btnState = "false"
    'print "btnState is FALSE"
  else
    m.btnState = "true"
    'print "btnState is TRUE"
  end if
  m.SetLabel()
  RefreshScreen(index)
  return m.btnState
End Function

REM /*------------------------------------------------- unlink_device -----
REM |  Function unlink_device
REM |
REM |  Purpose:
REM |      Unlinks the device from the account & exits the app
REM *-------------------------------------------------------------------*/

Function unlink_device(index as Integer)
  'print "unlinked device"
  RegDelete("token")
  RegDelete("subtitle_on")
  ExitUserInterface()
end Function

REM /*------------------------------------------------- SaveChangesToRegistry --
REM |  Function SaveChangesToRegistry
REM |
REM |  Purpose:
REM |      Writes changes to persistant registry
REM *-------------------------------------------------------------------*/

Sub SaveChangesToRegistry()
  'print "~~~~~~~~~~~~~~~~ SaveChangesToRegistry"
  RegWrite("subtitle_on",     m.subtitle_on)
  RegWrite("delete_allowed",  m.delete_allowed, "Permissions")
End Sub

Sub RefreshScreen(index=invalid)
  m.screen.SetContent(m.buttons)
  if (index <> invalid) then m.screen.SetFocusedListItem(index)
  m.screen.Show()
End Sub
