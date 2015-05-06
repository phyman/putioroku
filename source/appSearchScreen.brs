REM /*------------------------------------------------- Search -----
REM |  Function Search
REM |
REM |  Purpose:
REM |      Allows the user to search within their file set and displays results on screen
REM |
REM |  Parameter(s):
REM |      history (OUT)
REM |              a roArray that gets past to the FileBrowser call in order to display results
REM |
REM |  Returns:
REM |      Integer - but value isn’t used anywhere
REM *-------------------------------------------------------------------*/

function Search(history) as Integer
    displayHistory = true
    if (type(history) <> "roArray") then
      history = CreateObject("roArray", 1, true)
    end if
    screen  = CreateObject("roSearchScreen")
    port    = CreateObject("roMessagePort")
    screen.SetBreadcrumbText("", "Search in your files")
    screen.SetMessagePort(port)
    if displayHistory
        screen.SetSearchTermHeaderText("Recent Searches:")
        screen.SetSearchButtonText("Search")
        screen.SetClearButtonText("Clear history")
        screen.SetClearButtonEnabled(true) 'defaults to true'
        screen.SetSearchTerms(history)
    endif
    screen.Show()
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roSearchScreenEvent"
          if (msg.isScreenClosed()) then
              print "search screen closed"
              return -1
          else if msg.isCleared()
              print "search terms cleared"
              history.Clear()
          else if msg.isFullResult()
              print "full search: "; msg.GetMessage()
              history.Push(msg.GetMessage())
              if displayHistory
                screen.AddSearchTerm(msg.GetMessage())
              end if
              ut = CreateObject("roUrlTransfer")
              query = ut.Escape(msg.GetMessage())
              url ="https://api.put.io/v2/files/search/"+query+"?start_from=1&oauth_token="+m.token
              FileBrowser(url)
          endif
        endif
    end while
end function
