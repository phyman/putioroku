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
  screen = CreateObject("roListScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  items = CreateObject("roArray", 3, true)
  items[0] = {
      Title: "Unlink this device",
      HDSmallIconUrl: "pkg:/images/unlink.png",
  }
  if (m.subtitle_on = "on")
    s_title = "Disable subtitles"
  else
    s_title = "Enable subtitles"
  end if

  items[1] = {
      Title: s_title,
      HDSmallIconUrl: "pkg:/images/subtitles.png",
  }
  screen.SetContent(items)
  screen.Show()

  while (true)
      msg = wait(0, port)
      if (msg.isScreenClosed()) then
        return -1
      end if
      if (type(msg) = "roListScreenEvent") then
        if (msg.isListItemSelected()) then
          if (msg.GetIndex() = 0) then
            RegDelete("token")
            RegDelete("subtitle_on")
            screen.close()
            return 1
          else if (msg.GetIndex() = 1) then
            if (m.subtitle_on = "on")
              m.subtitle_on = "off"
            else
              m.subtitle_on = "on"
            end if
            return -1
          end if
        end if
      end if
  end while
end function
