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
  m.screen.SetMessagePort(port)

  ' Screen button "enums"
  m.btn             = CreateObject("roAssociativeArray")
  m.btn.SUBTITLES   = 0
  m.btn.UNLINK      = 1

  ' Screen button data
  m.choicesArr = CreateObject("roArray", m.btn.count(), true)

  if (m.subtitle_on = "on")
    s_title = "Disable subtitles"
  else
    s_title = "Enable subtitles"
  end if

  m.choicesArr[m.btn.SUBTITLES] = {
      Title:            s_title,
      HDSmallIconUrl:   "pkg:/images/subtitles.png",
      btnOnClickEvent:  toggle_subtitles,
  }

  m.choicesArr[m.btn.UNLINK] = {
      Title:            "Unlink this device",
      HDSmallIconUrl:   "pkg:/images/unlink.png",
      btnOnClickEvent:  unlink_device,
  }

  m.screen.SetContent(m.choicesArr)
  m.screen.Show()

  while (m.g.state.WAITING_FOR_USER_INPUT)
      msg = wait(0, port)

      if (msg.isScreenClosed()) then
        return -1
      end if

      if (type(msg) = "roListScreenEvent") then
        if (msg.isListItemSelected()) then
          selection = msg.GetIndex()
          if (selection <= m.choicesArr.count())
            m.choicesArr[selection].btnOnClickEvent(selection)
          end if
        end if
      end if

  end while
end function

REM /*------------------------------------------------- unlink_device -----
REM |  Function unlink_device
REM |
REM |  Purpose:
REM |      Unlinks the device from the account & exits the app
REM *-------------------------------------------------------------------*/

Function unlink_device(index as Integer)
  print "unlinked device"
  RegDelete("token")
  RegDelete("subtitle_on")
  End ' close the app & return to the Roku's Home panel
end Function

REM /*------------------------------------------------- toggle_subtitles -----
REM |  Function toggle_subtitles
REM |
REM |  Purpose:
REM |      Toggles the global subtitles setting and button label when selected
REM *-------------------------------------------------------------------*/

Sub toggle_subtitles(index as Integer)
  m = GetGlobalAA()
'  print "~~~~ toggle_subtitles::m.subtitle_on is " m.subtitle_on
  if (m.subtitle_on = "on")
    m.subtitle_on   = "off"
    m.choicesArr[index].Title = "Enable subtitles"
'    print "subtitles are OFF"
  else
    m.subtitle_on   = "on"
    m.choicesArr[index].Title = "Disable subtitles"
'    print "subtitles are ON"
  end if

  m.screen.SetContent(m.choicesArr)
  m.screen.SetFocusedListItem(index)
  m.screen.Show()
end Sub

