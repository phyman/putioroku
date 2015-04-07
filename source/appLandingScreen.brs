REM /*------------------------------------------------- RunLandingScreen -----
REM |  Function RunLandingScreen
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

function RunLandingScreen(facade) as Integer
  screen = CreateObject("roListScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)

  landing_items = CreateObject("roArray", 3, true)
  landing_items[0] = {
                      Title: "Your Files",
                      HDSmallIconUrl: "pkg:/images/your-files.png",
                    }
  landing_items[1] = {
                      Title: "Search",
                      HDSmallIconUrl: "pkg:/images/search.png",
                    }
  landing_items[2] = {
                      Title: "Settings",
                      HDSmallIconUrl: "pkg:/images/settings.png",
                    }
  screen.SetContent(landing_items)
  screen.Show()

  ' wait until user makes a choice
  while (true)
      msg = wait(0, port)
      if (msg.isScreenClosed()) Then
          facade.Close()
          return -1
      end if
      if (type(msg) = "roListScreenEvent") then
        if (msg.isListItemSelected()) then
          if (msg.GetIndex() = 0) then ' if the user selected "Your Files", generate the API call and ...
            list_root_url = "https://api.put.io/v2/files/list?start_from=1&oauth_token="+m.token
            FileBrowser(list_root_url) ' ... open the file browser view & display its contents
          else if (msg.GetIndex() = 1) then
            Search(false)
          else if (msg.GetIndex() = 2) then
            res = Settings()
            if (res = 1) then
              screen.close()
              facade.close()
            end if
          end if
        end if
      end if
  end while
end function
