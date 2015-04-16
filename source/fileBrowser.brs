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

  while (m.g.state.WAITING_FOR_USER_INPUT)
    msg = wait(0, port)
    if (msg.isScreenClosed()) then
      print "FileBrowser:: ScreenClosed"
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
          c_root    = parsed_ct[0]
          c_format  = parsed_ct[1]
          id        = files[focusedItem].ID.tostr()

          if (content_type = "application/x-directory") then
            item = {
              ContentType:  "episode"
              SDPosterUrl:  "pkg:/images/mid-folder.png"
              ID:           id
              title:        files[focusedItem].Title
            }
            'res = DeleteScreen(item)
            if (DeleteScreen(item) = -1) then
              files.delete(focusedItem)
              screen.SetContent(files)
            end if
          else if (c_root = "video") then
            item = {
              ContentType:  "episode"
              SDPosterUrl:  files[focusedItem].SDBackgroundImageUrl
              HDPosterUrl:  files[focusedItem].HDBackgroundImageUrl
              ID:           id
              title:        files[focusedItem].Title
              StartFrom:    files[focusedItem].StartFrom
            }
            ' res = DeleteScreen(item)
            if (DeleteScreen(item) = -1) then
              files.delete(focusedItem)
              screen.SetContent(files)
            end if
          else ' it is not a video nor a directory
            item = {
              ContentType: "episode"
              SDPosterUrl: "pkg:/images/mid-file.png"
              ID:          id
              title:       files[focusedItem].Title
            }
            ' res = DeleteScreen(item)
            if (DeleteScreen(item) = -1) then
              files.delete(focusedItem)
              screen.SetContent(files)
            end if
          end if
        end if
      end if

      ' SELECT key pressed
      if (msg.isListItemSelected()) then
        content_type  = files[msg.GetIndex()].ContentType
        r             = CreateObject("roRegex", "/", "")
        parsed_ct     = r.Split(content_type)
        c_root        = parsed_ct[0]
        c_format      = parsed_ct[1]
        id            = files[msg.GetIndex()].ID.tostr()
        'OK button press in an item view
        if (content_type = "application/x-directory") then
          if (files[msg.GetIndex()].size = 0) then
            item = {
              ContentType:  "episode"
              SDPosterUrl:  "pkg:/images/mid-folder.png"
              ID:           id
              title:        files[msg.GetIndex()].Title
              NonVideo:     true
            }
            ' res = SpringboardScreen(item)
            if (SpringboardScreen(item) = -1) then
              ' if item was deleted from the SpringboardScreen, refresh the content listing
              files.delete(msg.GetIndex())
              screen.SetContent(files)
            end if
          else ' construct the new dir path and recursively call FileBrowser to fetch its listing
            id = files[msg.GetIndex()].ID.tostr()
            url = "https://api.put.io/v2/files/list?oauth_token="+m.token+"&start_from=1&parent_id="+id
            print "-- Recursive call to FileBrowser"
            FileBrowser(url)
            print "---- Popped recursive call from FileBrowser"
          end if
        else if (c_root = "video") then
          if (c_format = "mp4") then
            putio_api = "https://api.put.io/v2/files/"+id+"/stream?oauth_token="+m.token
            item = {
              ContentType:  "episode"
              SDPosterUrl:  files[msg.GetIndex()].SDBackgroundImageUrl
              HDPosterUrl:  files[msg.GetIndex()].HDBackgroundImageUrl
              ID:           id
              title:        files[msg.GetIndex()].Title
              url:          putio_api
              StartFrom:    files[focusedItem].StartFrom
             }
            ' res = SpringboardScreen(item)
            if (SpringboardScreen(item) = -1) then
              files.delete(msg.GetIndex())
              screen.SetContent(files)
            end if
          else
            if (files[msg.GetIndex()].Mp4Available = true) then
              putio_api = "https://api.put.io/v2/files/"+id+"/mp4/stream?oauth_token="+m.token
              item = {
                ContentType:  "episode"
                SDPosterUrl:  files[msg.GetIndex()].SDBackgroundImageUrl
                HDPosterUrl:  files[msg.GetIndex()].HDBackgroundImageUrl
                ID:           id
                title:        files[msg.GetIndex()].Title
                url:          putio_api
                StartFrom:    files[focusedItem].StartFrom
               }
              ' res = SpringboardScreen(item)
              if (SpringboardScreen(item) = -1) then
                files.delete(msg.GetIndex())
                screen.SetContent(files)
              end if
            else
              putio_api = "https://api.put.io/v2/files/"+id+"/stream?oauth_token="+m.token
              item = {
                ContentType:  "episode"
                SDPosterUrl:  files[msg.GetIndex()].SDBackgroundImageUrl
                HDPosterUrl:  files[msg.GetIndex()].SDBackgroundImageUrl
                ID:           id
                title:        files[msg.GetIndex()].Title
                convert_mp4:  true
                url:          putio_api
                StartFrom:    files[focusedItem].StartFrom
              }
              ' res = SpringboardScreen(item)
              if (SpringboardScreen(item) = -1) then
                files.delete(msg.GetIndex())
                screen.SetContent(files)
              end if
            end if
          end if
        else
          item = {
            ContentType:  "episode"
            SDPosterUrl:  "pkg:/images/mid-file.png"
            ID:           id
            title:        files[msg.GetIndex()].Title
            NonVideo:     true
          }
          ' res = SpringboardScreen(item)
          if (SpringboardScreen(item) = -1) then
            files.delete(msg.GetIndex())
            screen.SetContent(files)
          end if
        end if
      end if
    end if
  end while
end function

REM /*------------------------------------------------- GetFileList -----
REM |  Function GetFileList
REM |
REM |  Purpose:
REM |      Creates an roAssociativeArray of all files objects at the target
REM |       URL location and populates objects meta data with screen shot
REM |       and/or icon assets to display
REM |
REM |       note: ONLY used by FileBrowser
REM |
REM |  Parameter(s):
REM |      URL (IN)
REM |              Target URL to fetch file listing from
REM |
REM |  Returns:
REM |      A populated roAssociativeArray with file information and
REM |       associated meta data
REM *-------------------------------------------------------------------*/

function GetFileList(url as string) as object
  request = MakeRequest()

  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.setUrl(url)
  result = CreateObject("roAssociativeArray")

  if (request.AsyncGetToString())
    while (m.g.state.WAITING_FOR_USER_INPUT)
      msg = wait(0, port)
      if (type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if (code = m.g.response_code.SUCCESS)
          files = CreateObject("roArray", 10, true)
          json = ParseJSON(msg.GetString())
          if (json.DoesExist("parent")) then
            result.parent = {name: json["parent"].name, parent_id: json["parent"].parent_id}
          end if
          start_from = invalid
          for each kind in json["files"]
            if (kind.content_type = "application/x-directory") then
              hd_screenshot = "pkg:/images/mid-folder.png"
              sd_screenshot = "pkg:/images/mid-folder.png"
              sd_small = "pkg:/images/small-folder.png"
              hd_small = "pkg:/images/small-folder.png"
            else
              r = CreateObject("roRegex", "/", "")
              parsed_ct = r.Split(kind.content_type)
              c_root = parsed_ct[0]
              if (c_root <> "video") then
                sd_screenshot = "pkg:/images/mid-file.png"
                hd_screenshot = "pkg:/images/mid-file.png"
                sd_small = "pkg:/images/file-icon.png"
                hd_small = "pkg:/images/file-icon.png"
              else
                r = CreateObject("roRegex", "https://", "")
                ss = r.ReplaceAll(kind.screenshot, "http://")
                sd_screenshot = ss
                hd_screenshot = ss
                sd_small = "pkg:/images/playable-icon.png"
                hd_small = "pkg:/images/playable-icon.png"
                start_from = kind.start_from
              end if
            endif

            item = {
              Title:                  kind.name,
              ID:                     kind.id,
              Mp4Available:           kind.is_mp4_available,
              ContentType:            kind.content_type,

              SDBackgroundImageUrl:   hd_screenshot,
              HDPosterUrl:            hd_screenshot,
              SDPosterUrl:            sd_screenshot,
              ShortDescriptionLine1:  kind.name,

              SDSmallIconUrl:         sd_small,
              HDSmallIconUrl:         hd_small,
              size:                   kind.size,
              StartFrom:              start_from,
            }
            files.push(item)
          end for
          result.files = files
          return result
        endif
      else if (event = invalid)
        request.AsyncCancel()
      endif
    end while
  endif
  return invalid
end function
