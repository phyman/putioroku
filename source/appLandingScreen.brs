REM /*------------------------------------------------- initLandingScreen -----
REM |  Function initLandingScreen
REM |
REM |  Purpose:
REM |      First user interactive screen displaying choices:
REM |       Files, Search and Settings
REM |
REM |     note: This is the first interactive screen the users sees when starting the app
REM |
REM |  Parameter(s):
REM |      facade (IN)
REM |              The screen to display while sub-screens populate
REM *-------------------------------------------------------------------*/

function initLandingScreen(facade) as Integer
  choices = initChoices()
  screen  = CreateObject("roListScreen")
  port    = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  screen.SetContent(choices)

  screen.Show()

  while (m.g.state.WAITING_FOR_USER_INPUT)
    msg = wait(0, port)

    if (msg.isScreenClosed()) then
        facade.Close()
        return -1
    end if

    if (type(msg) = "roListScreenEvent") then
      if (msg.isListItemSelected()) then
        selection = msg.GetIndex()
        if (selection <= choices.count())
          choices[selection].btnOnClickEvent()
        end if
      end if
    end if

  end while

end function

Function initChoices()
  btn             = CreateObject("roAssociativeArray")
  btn.YOUR_FILES  = 0
  btn.SEARCH      = 1
  btn.SETTINGS    = 2

  choicesArr = CreateObject("roArray", btn.count(), true)
  choicesArr[btn.YOUR_FILES] = {
                      Title: "Your Files",
                      HDSmallIconUrl: "pkg:/images/your-files.png",
                      btnOnClickEvent: show_Files,
                    }
  choicesArr[btn.SEARCH] = {
                      Title: "Search",
                      HDSmallIconUrl: "pkg:/images/search.png",
                      btnOnClickEvent: show_Search,
                    }
  choicesArr[btn.SETTINGS] = {
                      Title: "Settings",
                      HDSmallIconUrl: "pkg:/images/settings.png",
                      btnOnClickEvent: show_Settings,
                    }
  return choicesArr
end Function

Function show_Files()
  list_root_url = "https://api.put.io/v2/files/list?start_from=1&oauth_token="+GetGlobalAA().token
  FileBrowser(list_root_url) ' open the file browser view & display its contents
end Function

Function show_Search()
  Search(false)
end Function

'REM Should not call settings from choicesArr b/c it will not be in
'REM  correct scope for global var lookup
Function show_Settings() As Integer
  Settings()
end Function
