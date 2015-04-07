REM /*------------------------------------------------- FileBrowser -----
REM |  Function FileBrowser
REM |
REM |  Purpose:
REM |      Displays the files at the target URL with context aware icons
REM |       and handles user button presses (key) events
REM |
REM |  Parameter(s):
REM |      URL (IN)
REM |              The URL where to fetch the file listing from
REM *-------------------------------------------------------------------*/

function FileBrowser(url as string) as Integer
  screen = CreateObject("roListScreen")
  port = CreateObject("roMessagePort")
  screen.SetMessagePort(port)
  l = Loading()
  result = GetFileList(url)
  if (result.DoesExist("parent")) then
    screen.SetBreadcrumbText("", result.parent.name)
  else
    if (type(screen) = "roListScreen") then
      screen.SetHeader("Search Results")
    end if
  end if

  files = result.files
  screen.SetContent(files)
  screen.Show()
  l.close()


  focusedItem = invalid

  while (true)
    msg = wait(0, port)
    if (msg.isScreenClosed()) then
        return -1
    end if

    if (type(msg) = "roListScreenEvent") then
      if msg.isListItemFocused()
          focusedItem = msg.GetIndex()
      end if

      REM
      REM Button press (key) handler
      REM
      if (msg.isRemoteKeyPressed()) then

        ' INFO KEY (*) pressed
        if (msg.GetIndex() = 10) then
          content_type = files[focusedItem].ContentType

          r = CreateObject("roRegex", "/", "")
          parsed_ct = r.Split(content_type)
          c_root = parsed_ct[0]
          c_format = parsed_ct[1]
          id = files[focusedItem].ID.tostr()

          if (content_type = "application/x-directory") then
            item = {
              ContentType: "episode"
              SDPosterUrl: "pkg:/images/mid-folder.png"
              ID: id
              title: files[focusedItem].Title
            }
            res = DeleteScreen(item)
            if (res = -1) then
              files.delete(focusedItem)
              screen.SetContent(files)
            end if
          else if (c_root = "video") then
            item = {
              ContentType: "episode"
              SDPosterUrl: files[focusedItem].SDBackgroundImageUrl
              HDPosterUrl: files[focusedItem].HDBackgroundImageUrl
              ID: id
              title: files[focusedItem].Title
              StartFrom: files[focusedItem].StartFrom
            }
            res = DeleteScreen(item)
            if (res = -1) then
              files.delete(focusedItem)
              screen.SetContent(files)
            end if
          else ' it is not a video nor a directory
            item = {
              ContentType: "episode"
              SDPosterUrl: "pkg:/images/mid-file.png"
              ID: id
              title: files[focusedItem].Title
            }
            res = DeleteScreen(item)
            if (res = -1) then
              files.delete(focusedItem)
              screen.SetContent(files)
            end if
          end if
        end if
      end if

      ' SELECT key pressed
      if (msg.isListItemSelected()) then
        content_type = files[msg.GetIndex()].ContentType
        r = CreateObject("roRegex", "/", "")
        parsed_ct = r.Split(content_type)
        c_root = parsed_ct[0]
        c_format = parsed_ct[1]
        id = files[msg.GetIndex()].ID.tostr()
        'OK button press in an item view
        if (content_type = "application/x-directory") then
          if (files[msg.GetIndex()].size = 0) then
            item = {
              ContentType: "episode"
              SDPosterUrl: "pkg:/images/mid-folder.png"
              ID: id
              title: files[msg.GetIndex()].Title
              NonVideo: true
            }
            res = SpringboardScreen(item)
            if (res = -1) then
              ' if item was deleted from the SpringboardScreen, refresh the content listing
              files.delete(msg.GetIndex())
              screen.SetContent(files)
            end if
          else ' construct the new dir path and recursively call FileBrowser to fetch its listing
            id = files[msg.GetIndex()].ID.tostr()
            url = "https://api.put.io/v2/files/list?oauth_token="+m.token+"&start_from=1&parent_id="+id
            FileBrowser(url)
          end if
        else if (c_root = "video") then
          if (c_format = "mp4") then
            putio_api = "https://api.put.io/v2/files/"+id+"/stream?oauth_token="+m.token
            item = {
              ContentType: "episode"
              SDPosterUrl: files[msg.GetIndex()].SDBackgroundImageUrl
              HDPosterUrl: files[msg.GetIndex()].HDBackgroundImageUrl
              ID: id
              title: files[msg.GetIndex()].Title
              url: putio_api
              StartFrom: files[focusedItem].StartFrom
             }
            res = SpringboardScreen(item)
            if (res = -1) then
              files.delete(msg.GetIndex())
              screen.SetContent(files)
            end if
          else
            if (files[msg.GetIndex()].Mp4Available = true) then
              putio_api = "https://api.put.io/v2/files/"+id+"/mp4/stream?oauth_token="+m.token
              item = {
                ContentType:"episode"
                SDPosterUrl: files[msg.GetIndex()].SDBackgroundImageUrl
                HDPosterUrl: files[msg.GetIndex()].HDBackgroundImageUrl
                ID: id
                title: files[msg.GetIndex()].Title
                url: putio_api
                StartFrom: files[focusedItem].StartFrom
               }
              res = SpringboardScreen(item)
              if (res = -1) then
                files.delete(msg.GetIndex())
                screen.SetContent(files)
              end if
            else
              putio_api = "https://api.put.io/v2/files/"+id+"/stream?oauth_token="+m.token
              item = {
                ContentType:"episode"
                SDPosterUrl: files[msg.GetIndex()].SDBackgroundImageUrl
                HDPosterUrl: files[msg.GetIndex()].SDBackgroundImageUrl
                ID: id
                title: files[msg.GetIndex()].Title
                convert_mp4: true
                url: putio_api
                StartFrom: files[focusedItem].StartFrom
              }
              res = SpringboardScreen(item)
              if (res = -1) then
                files.delete(msg.GetIndex())
                screen.SetContent(files)
              end if
            end if
          end if
        else
          item = {
            ContentType: "episode"
            SDPosterUrl: "pkg:/images/mid-file.png"
            ID: id
            title: files[msg.GetIndex()].Title
            NonVideo: true
          }
          res = SpringboardScreen(item)
          if (res = -1) then
            files.delete(msg.GetIndex())
            screen.SetContent(files)
          end if
        end if
      end if
    end if
  end while
end function
