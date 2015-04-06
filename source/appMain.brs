function Main()
  InitTheme()
  facade = CreateObject("roParagraphScreen")
  facade.Show()
  token = RegRead("token")
  ' if the device isn't already linked, ask
  ' the user to do so now
  if (token = invalid) then
    res = ShowLinkScreen(facade)
    ' TODO: figure out how the <sub> ShowLinkScreen returns
    ' and assigns an int to the var res (since subs are intrinsically
    ' void return types)
    if (res = -1) then
      return -1
    end if
  else
    m.token = token
  end if
  m.subtitle_on = RegRead("subtitle_on")
  RunLandingScreen(facade)
end function

REM /*------------------------------------------------- GetLinkingCode -----
REM |  Function GetLinkingCode
REM |
REM |  Purpose:
REM |      Fetches a link code from put.io to tie the account and
REM |      device together
REM |
REM |  Returns:
REM |      The json formatted link key (code) if it exists,
REM |      otherwise returns <invalid>
REM *-------------------------------------------------------------------*/

function GetLinkingCode() as Dynamic
  request = MakeRequest()
  device_id = GetDeviceESN()
  url = "https://put.io/roku/key/"+device_id
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.SetUrl(url)
  if (request.AsyncGetToString())
    msg = wait(0, port)
    if (type(msg) = "roUrlEvent")
      code = msg.GetResponseCode()
      if (code = 200) ' Successful response
        json = ParseJSON(msg.GetString())
        if (json.DoesExist("key")) then
          return json["key"]
        end if
      endif
    else if (event = invalid)
      request.AsyncCancel()
    endif
  endif
  return invalid
end function

REM /*------------------------------------------------- ValidateLinkingCode -----
REM |  Function ValidateLinkingCode
REM |
REM |  Purpose:
REM |      Validates the device is authorized to access the Put.io API
REM |
REM |  Returns:
REM |      1 if authorization was successful
REM *-------------------------------------------------------------------*/

function ValidateLinkingCode() as Integer
  request = MakeRequest()

  url = "https://put.io/roku/check"
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.SetUrl(url)
  device_id = GetDeviceESN()
  if (request.AsyncPostFromString("device_id="+device_id))
    msg = wait(0, port)
    if (type(msg) = "roUrlEvent")
      code = msg.GetResponseCode()
      if (code = 200) ' Successful response
        json = ParseJSON(msg.GetString())
        if (json.DoesExist("oauth_token")) then
          token = json["oauth_token"]
          RegWrite("token", token)
          RegWrite("subtitle_on", "on")
          m.token = token
          return 1
        end if
      end if
    end if
  end if
end function

REM /*------------------------------------------------- ShowLinkScreen -----
REM |  Sub Function ShowLinkScreen
REM |
REM |  Purpose:
REM |      Displays the interactive Link Screen UI to allow users to pair
REM |       their account with the device - this is normally only done once
REM *-------------------------------------------------------------------*/

sub ShowLinkScreen(facade) as Integer
  dt = CreateObject("roDateTime")

  ' create a roCodeRegistrationScreen and assign it a roMessagePort
  port = CreateObject("roMessagePort")
  screen = CreateObject("roCodeRegistrationScreen")
  screen.SetMessagePort(port)

  ' add some header text
  screen.AddHeaderText("  Link this Roku to your put.io account")
  ' add some buttons
  screen.AddButton(1, "Get new code")
  screen.AddButton(2, "Back")
  ' Focal text should give specific instructions to the user
  screen.AddFocalText("Go to put.io/roku, log into your account, and enter the following:", "spacing-normal")

  ' display a retrieving message until we get a linking code
  screen.SetRegistrationCode("Retrieving...")
  screen.Show()

  ' get a new code
  linkingCode = GetLinkingCode()
  if linkingCode <> invalid
    screen.SetRegistrationCode(linkingCode)
  else
    screen.SetRegistrationCode("Failed to get code...")
  end if

  screen.Show()
  current = dt.AsSeconds()+300

  while true
    ' we want to poll the API every 5 seconds for validation,
    msg = Wait(5000, screen.GetMessagePort())

    if msg = invalid
      ' poll the API for validation
      if (ValidateLinkingCode() = 1)
        ' if validation succeeded, close the screen
        exit while
      end if

      dt.Mark()
      if dt.AsSeconds() > current
        ' the code expired. display a message, then get a new one
        d = CreateObject("roMessageDialog")
        dPort = CreateObject("roMessagePort")
        d.SetMessagePort(dPort)
        d.SetTitle("Code Expired")
        d.SetText("This code has expired. Press OK to get a new one")
        d.AddButton(1, "OK")
        d.Show()

        Wait(0, dPort)
        d.Close()
        current = dt.AsSeconds()+300
        screen.SetRegistrationCode("Retrieving...")
        screen.Show()
        linkingCode = GetLinkingCode()
        if linkingCode <> invalid
          screen.SetRegistrationCode(linkingCode)
        else
          screen.SetRegistrationCode("Failed to get code...")
        end if
        screen.Show()
      end if
    else if type(msg) = "roCodeRegistrationScreenEvent"
      if msg.isScreenClosed()
          screen.Close()
          facade.Close()
          return -1
      else if msg.isButtonPressed()
        if msg.GetIndex() = 1
          ' the user wants a new code
          linkingCode = GetLinkingCode()
          current = dt.AsSeconds()+300
          if linkingCode <> invalid
            screen.SetRegistrationCode(linkingCode)
          else
            screen.SetRegistrationCode("Failed to get code...")
          end if
          screen.Show()
        else if msg.GetIndex() = 2
          ' the user wants to close the screen
          screen.Close()
          facade.Close()
          return -1
        end if
      end if
    end if
  end while
  screen.Close()
end sub

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

REM /*------------------------------------------------- InitTheme -----
REM |  Function InitTheme
REM |
REM |  Purpose:
REM |      Sets the app’s theme variables used in its UI
REM *-------------------------------------------------------------------*/

function InitTheme()
    app = CreateObject("roAppManager")

    secondaryText   = "#FFED6D"
    primaryText     = "#FFED6D"
    buttonText      = "#C0C0C0"
    buttonHighlight = "#ffffff"
    backgroundColor = "#4D4D4D"

    ' TODO: Replace #colorValues with symbolic names

    theme = {
        BackgroundColor: backgroundColor
        OverhangSliceHD: "pkg:/images/roku-app-overhang.png"
        OverhangSliceSD: "pkg:/images/roku-app-overhang.png"
        OverhangLogoHD: "pkg:/images/roku-app-logo.png"
        OverhangLogoSD: "pkg:/images/roku-app-logo.png"
        OverhangOffsetSD_X: "230"
        OverhangOffsetSD_Y: "72"
        OverhangOffsetHD_X: "230"
        OverhangOffsetHD_Y: "72"
        BreadcrumbTextLeft: "#FFED6D"
        BreadcrumbTextRight: "#FFED6D"
        BreadcrumbDelimiter: "#FFED6D"
        ThemeType: "generic-dark"
        ListItemText: secondaryText
        ListItemHighlightText: primaryText
        ListScreenDescriptionText: secondaryText
        ListItemHighlightHD: "pkg:/images/selected-bg.png"
        ListItemHighlightSD: "pkg:/images/selected-bg.png"
        SpringboardTitleText: "#FFED6D"
        ButtonNormalColor: "#FFED6D"
        ButtonHighlightColor: "#FFED6D"
        ButtonMenuHighlightText: "#FFED6D"
        ButtonMenuNormalOverlayText: "#FFED6D"
        ButtonMenuNormalText: "#FFED6D"
        ParagraphBodyText: "#FFED6D"
        ParagraphHeaderText: "#FFED6D"
        RegistrationFocalColor: "FFFFFF"
        DialogBodyText: "#FFED6D"
        DialogTitleText: "#FFED6D"
        RegistrationCodeColor: "#FFED6D"
        RegistrationFocalColor: "#FFED6D"
        RegistrationFocalRectColor: "#FFED6D"
        RegistrationFocalRectHD: "#FFED6D"
        RegistrationFocalRectSD: "#FFED6D"
    }
    app.SetTheme( theme )
end function

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
    while (true)
      msg = wait(0, port)
      if (type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if (code = 200)
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
              Title: kind.name,
              ID: kind.id,
              Mp4Available: kind.is_mp4_available,
              ContentType: kind.content_type,
              SDBackgroundImageUrl: hd_screenshot,
              HDPosterUrl: hd_screenshot,
              SDPosterUrl: sd_screenshot,
              ShortDescriptionLine1: kind.name,
              SDSmallIconUrl: sd_small,
              HDSmallIconUrl: hd_small,
              size: kind.size,
              StartFrom: start_from,
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

REM /*------------------------------------------------- SpringboardScreen -----
REM |  Function SpringboardScreen
REM |
REM |  Purpose:
REM |      The item view screen - The Springboard Screen shows detailed
REM |       information about an individual piece of content and provides
REM |       options for actions that may be taken on that content.
REM |      Normal options are: Play & Delete
REM |      Exception options: Try to Play & Convert to MP4
REM |
REM |  Parameter(s):
REM |      item (IN)
REM |              The item/object to apply selected options upon
REM |
REM |  Returns:
REM |      Integer: -1 if item is deleted, otherwise 0 for a normal exit
REM |
REM *-------------------------------------------------------------------*/

function SpringboardScreen(item as object) As Integer
    print "SpringboardScreen"
    if (item.DoesExist("NonVideo") = false) then
      l = Loading()
      redirected = ResolveRedirect(item["url"])
      item["url"] = redirected
    end if

    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)

    screen.SetDescriptionStyle("video") 'audio, movie, video, generic
                                        ' generic+episode=4x3,
    screen.ClearButtons()

    ' MP4 conversion and play options are offered here
    if (item.DoesExist("convert_mp4") = true) then
      request = MakeRequest()

      url = "https://api.put.io/v2/files/"+item["ID"]+"/mp4?oauth_token="+m.token
      port = CreateObject("roMessagePort")
      request.SetMessagePort(port)
      request.SetUrl(url)
      if (request.AsyncGetToString())
        msg = wait(0, port)
        if (type(msg) = "roUrlEvent") then
          code = msg.GetResponseCode()
          if (code = 200) then ' Successful response
            result = ParseJSON(msg.GetString())
            if (result["mp4"]["status"] = "NOT_AVAILABLE") then
              screen.AddButton(1, "Try to play")
              screen.AddButton(2, "Convert to MP4")
            else if (result["mp4"]["status"] = "COMPLETED") then
              screen.AddButton(1, "Play")
            else if (result["mp4"]["status"] = "CONVERTING")
              screen.AddButton(1, "Try to play")
              percent_done = result["mp4"]["percent_done"]
              item.Description = "Converting to MP4...  "+percent_done.tostr()+"%"
              'TODO: On this screen the "Try to play" button is displayed, but should it be??
            else if (result["mp4"]["status"] = "IN_QUEUE")
              screen.AddButton(1, "Try to play")
              item.Description = "In queue, please wait..."
            end if
          end if
        else if (event = invalid)
          request.AsyncCancel()
          screen.AddButton(1, "Try to play")
          screen.AddButton(2, "Convert to MP4")
        end if
      end if
    else
      if (item.DoesExist("nonVideo") = false) then
        screen.AddButton(1, "Play")
      end if
    end if

    if (item.DoesExist("NonVideo") = false) then
        subtitles = invalid
        request = MakeRequest()
        url = "https://api.put.io/v2/files/"+item["ID"]+"/subtitles?oauth_token="+m.token
        port = CreateObject("roMessagePort")
        request.SetMessagePort(port)
        request.SetUrl(url)
        if (request.AsyncGetToString())
          msg = wait(0, port)
          if (type(msg) = "roUrlEvent") then
            code = msg.GetResponseCode()
            if (code = 200) then
                subtitles = ParseJSON(msg.GetString())
                for each subtitle in subtitles["subtitles"]
                  if (subtitles.default = subtitle.key)
                    screen.AddButton(3, "Subtitles")
                  endif
                end for
            end if
          end if
        end if
    end if

    screen.AddButton(4, "Delete")

    screen.AllowUpdates(false)
    if item <> invalid and type(item) = "roAssociativeArray"
        screen.SetContent(item)
    endif

    screen.SetStaticRatingEnabled(false)
    screen.AllowUpdates(true)

    screen.Show()
    if (item.DoesExist("NonVideo") = false) then
      l.close()
    end if

    subtitle_index = invalid
    while true
      msg = wait(0, screen.GetMessagePort())
      if type(msg) = "roSpringboardScreenEvent"
        if msg.isScreenClosed()
          exit while
        else if msg.isButtonPressed()
          if msg.GetIndex() = 1
            if subtitle_index = invalid
              subtitle = subtitles.default
            else if subtitle_index = 0
              'Ayni scopeda degismis olabilir bu degisken. o yuzden tekrar ediyoruz'
              subtitle = invalid
            else
              subtitle = subtitles["subtitles"][subtitle_index-1]["key"]
            end if
            DisplayVideo(item, subtitle)
          else if msg.GetIndex() = 2
            ConvertToMp4(item)
          else if msg.GetIndex() = 3
            tmp = SelectSubtitle(subtitles, item.SDPosterUrl)
            if tmp <> invalid
              'selectsubtitle invalid ya da 0, 1, 2... seklinde bir sonuc donuyor'
              'default subtitle secimi yapilan durumla karismamasi icin burdaki invalidi dikkate almiyoruz'
              'geri ok tusuyla hicbir sey yapmadan geri donulurse invalid donuyor'
              subtitle_index = tmp
            end if
          else if msg.GetIndex() = 4
            res = DeleteItem(item)
            if (res = true) then
              return -1
            end if
          end if
        endif
      endif
    end while
end function

REM /*------------------------------------------------- DisplayVideo -----
REM |  Function DisplayVideo
REM |
REM |  Purpose:
REM |      Play the selected video
REM |
REM |  Parameter(s):
REM |      args (IN)
REM |              Video items args such as Title, ImageUrl, ID, playhead index (StartFrom)
REM |
REM |      subtitle (IN)
REM |              Selected subtitle option
REM *-------------------------------------------------------------------*/

function DisplayVideo(args as object, subtitle)
    print "Displaying video: "
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    bitrates  = [0]
    qualities = ["HD"]
    StreamFormat = "mp4"
    title = args["title"]

    urls = [args["url"]]
    if type(args["url"]) = "roString" and args["url"] <> "" then
        urls[0] = args["url"]
    end if
    if type(args["StreamFormat"]) = "roString" and args["StreamFormat"] <> "" then
        StreamFormat = args["StreamFormat"]
    end if
    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = StreamFormat
    videoclip.Title = title
    if (m.subtitle_on = "on")
      if subtitle <> invalid
        videoclip.SubtitleUrl = "https://api.put.io/v2/files/"+args["ID"]+"/subtitles/"+subtitle+"?oauth_token="+m.token
      end if
    end if

    videoclip.PlayStart = GetStartFrom(args)

    video.SetCertificatesFile("common:/certs/ca-bundle.crt")
    video.AddHeader("X-Roku-Reserved-Dev-Id", "")
    video.AddHeader("User-Agent", "PutioRoku Client 1.0")
    video.InitClientCertificates()

    video.show()
    video.SetContent(videoclip)
    video.ShowSubtitle(true)
    video.SetPositionNotificationPeriod(30)
    startFromDisabled = false
    while true
      msg = wait(0, video.GetMessagePort())
      if type(msg) = "roVideoScreenEvent"
          if msg.isScreenClosed() then 'ScreenClosed event
              print "Closing video screen"
              exit while
          else if (msg.isPlaybackPosition() and startFromDisabled = false) then
              currentpos = msg.GetIndex()
              m.start_from = currentpos
              m.current_id = args["ID"].toint()
              if currentpos <> 0
                request = MakeRequest()
                url = "https://api.put.io/v2/files/"+args["ID"]+"/start-from/set?oauth_token="+m.token
                port = CreateObject("roMessagePort")
                request.SetMessagePort(port)
                request.SetUrl(url)
                if (request.AsyncPostFromString("time="+currentpos.tostr()))
                  event = wait(0, port)
                  code = event.GetResponseCode()
                  if (code = 412)
                    startFromDisabled = true
                  end if
                  if (event = invalid)
                    request.AsyncCancel()
                  end if
                end if
              end if
          else if msg.isRequestFailed()
              print "play failed: "; msg.GetMessage()
          endif
      end if
    end while
end function

REM /*------------------------------------------------- ResolveRedirect -----
REM |  Function ResolveRedirect
REM |
REM |  Purpose:
REM |      Fetches a redirect URL from the API if it is present
REM |
REM |  Parameter(s):
REM |      str (IN)
REM |              The constructed API URL to call
REM |
REM |  Returns:
REM |      A redirect URL as a string if the API provides one, otherwise just returns str back
REM *-------------------------------------------------------------------*/

function ResolveRedirect(str As String) As String
    http = MakeRequest()
    http.SetUrl( str )
    event = http.Head()
    headers = event.GetResponseHeaders()
    redirect = headers.location
    if ( redirect <> invalid AND redirect <> str )
      str = redirect
    endif
    'r = CreateObject("roRegex", "https://", "")'
    'str = r.ReplaceAll(str, "http://")'
    return str
end function

REM /*------------------------------------------------- ConvertToMp4 -----
REM |  Function ConvertToMp4
REM |
REM |  Purpose:
REM |      Starts the MP4 conversion to the target item as an asynchronous process
REM |
REM |  Parameter(s):
REM |      item (IN)
REM |              Target item to convert to MP4
REM *-------------------------------------------------------------------*/

function ConvertToMp4(item as Object) as void
  request = MakeRequest()
  lc = Loading()
  url = "https://api.put.io/v2/files/"+item["ID"]+"/mp4?oauth_token="+m.token
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.SetUrl(url)
  if (request.AsyncPostFromString(""))
    msg = wait(0, port)
    if (type(msg) = "roUrlEvent")
      lc.close()
    else if (msg = invalid)
      request.AsyncCancel()
      lc.close()
    endif
  endif
end function

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
    screen = CreateObject("roSearchScreen")
    port = CreateObject("roMessagePort")
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
              FileBrowser(url, history)
          endif
        endif
    end while
end function

REM /*------------------------------------------------- DeleteItem -----
REM |  Function DeleteItem
REM |
REM |  Purpose:
REM |      Deletes the target item from account with an asynchronous request
REM |
REM |  Parameter(s):
REM |      item (IN)
REM |              The target item to delete
REM |
REM |  Returns:
REM |      True if item is succcessfully deleted, false otherwise
REM *-------------------------------------------------------------------*/

function DeleteItem(item as object) as Boolean
  l = Loading()
  request = MakeRequest()
  request.EnableEncodings(true)
  url = "https://api.put.io/v2/files/delete?oauth_token="+m.token
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.SetUrl(url)
  request.AddHeader("Content-Type","application/x-www-form-urlencoded")
  if (request.AsyncPostFromString("file_ids="+item["ID"]))
    msg = wait(0, port)
    if (type(msg) = "roUrlEvent")
      l.close()
      code = msg.GetResponseCode()
      if (code = 200)
        return true
      endif
    else if (event = invalid)
      request.AsyncCancel()
      l.close()
      return false
    endif
  endif
end function ' DeleteItem

REM /*------------------------------------------------- Loading -----
REM |  Function Loading
REM |
REM |  Purpose:
REM |      Displays loading splash screen and “Thinking…” text
REM |
REM |  Returns:
REM |      roImageCanvas object to display
REM *-------------------------------------------------------------------*/

Sub Loading() as Object
  canvasItems = [
        {
            url:"pkg:/images/app-icon.png"
            TargetRect:{x:500,y:240,w:290,h:218}
        },
        {
            Text:"Thinking..."
            TextAttrs:{Color:"#FFED6D", Font:"Medium",
            HAlign:"HCenter", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:390,y:467,w:500,h:60}
        }
  ]

  canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")
  canvas.SetMessagePort(port)
  'Set opaque background'
  canvas.SetLayer(0, {Color:"#4D4D4D", CompositionMode:"Source"})
  canvas.SetRequireAllImagesToDraw(true)
  canvas.SetLayer(1, canvasItems)
  canvas.Show()
  return canvas
end Sub

REM /*------------------------------------------------- CheckSubtitle -----
REM |  Function CheckSubtitle
REM |
REM |  Purpose:
REM |      UNUSED - Appears to check if the subtitle file can be found &
REM |       is non-zero in size
REM |
REM |  Returns:
REM |      a json formatted lang(uage) setting if found & valid,
REM |       “invalid” otherwise
REM *-------------------------------------------------------------------*/

function CheckSubtitle()
  l = Loading()
  request = MakeRequest()

  url = "https://api.put.io/v2/account/settings?oauth_token="+m.token
  port = CreateObject("roMessagePort")
  request.SetMessagePort(port)
  request.setUrl(url)

  if (request.AsyncGetToString())
    while (true)
      msg = wait(0, port)
      l.close()
      if (type(msg) = "roUrlEvent")
        code = msg.GetResponseCode()
        if (code = 200)
          json = ParseJSON(msg.GetString())
          lang = json["settings"]["default_subtitle_language"]
          if (Len(lang) = 0)
            return invalid
          end if
          return lang
        end if
      end if
    end while
  end if
  l.close()
  return invalid
end function

REM /*------------------------------------------------- RegRead -----
REM |  Function RegRead
REM |
REM |  Purpose:
REM |      Locates and returns the value of the registry key if found
REM |
REM |  Parameter(s):
REM |      key (IN)
REM |              The key to locate and read
REM |
REM |      section (IN)
REM |              The section of the registry where the key should be found;
REM |               default value is ‘invalid' if not provided
REM |
REM |  Returns:
REM |      The key's value if found; invalid otherwise.
REM *-------------------------------------------------------------------*/

function RegRead(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return invalid
end function

REM /*------------------------------------------------- RegWrite -----
REM |  Function RegWrite
REM |
REM |  Purpose:
REM |      Locates and write val(ue) to the registry key if found
REM |
REM |  Parameter(s):
REM |      key (IN)
REM |              The key to locate and write the val(ue) into
REM |
REM |      val (IN)
REM |               The val(ue) to write to the registry's key
REM |
REM |      section (IN)
REM |              The section of the registry where the key should be found;
REM |               default value is ‘invalid' if not provided
REM |
REM *-------------------------------------------------------------------*/

function RegWrite(key, val, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it'
end function

REM /*------------------------------------------------- RegDelete -----
REM |  Function RegDelete
REM |
REM |  Purpose:
REM |      Deletes the targeted registry key.
REM |
REM |  Parameter(s):
REM |      key (IN)
REM |              The target registry key to delete
REM |
REM |      If the section is invalid, it creates it, then deletes the key
REM |       BUT, there doesn’t seem to be any reason to do this...
REM |       QED this should be changed to just return if the section is invalid
REM |       to begin with...
REM |
REM *-------------------------------------------------------------------*/

function RegDelete(key, section=invalid)
    ' TODO check and see if this can't just return if section is invalid coming in
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
end function

REM /*------------------------------------------------- MakeRequest -----
REM |  Function MakeRequest
REM |
REM |  Purpose:
REM |      Creates and populates a URL Transfer object with Cert file name
REM |      and adds header info needed for authentication purposes.
REM |
REM |  Returns:
REM |      URL Transfer object which, after authentication, allows
REM |     reading & writing to the target web server.
REM *-------------------------------------------------------------------*/

function MakeRequest() as Object
  request = CreateObject("roUrlTransfer")
  request.SetCertificatesFile("common:/certs/ca-bundle.crt")
  request.AddHeader("X-Roku-Reserved-Dev-Id", "")
  request.AddHeader("User-Agent", "PutioRoku Client 1.0")
  request.InitClientCertificates()
  return request
end function

REM /*------------------------------------------------- GetDeviceESN -----
REM |  Function GetDeviceESN
REM |
REM |  Purpose:
REM |      Reads & returns the serial number of the target device
REM |
REM |  Returns:
REM |      Returns the serial number of the target device as a string
REM *-------------------------------------------------------------------*/

function GetDeviceESN()
    return CreateObject("roDeviceInfo").GetDeviceUniqueId()
end function

REM /*------------------------------------------------- DeleteScreen -----
REM |  Function DeleteScreen
REM |
REM |  Purpose:
REM |      Displays a screen with only a Delete option present
REM |
REM |  Parameter(s):
REM |      item (IN)
REM |              The target item to delete
REM |
REM |  Returns:
REM |      -1 if item was successfully deleted
REM *-------------------------------------------------------------------*/

function DeleteScreen(item as object) As Integer
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)
    screen.SetDescriptionStyle("video")
    screen.ClearButtons()
    screen.AddButton(1, "Delete")
    screen.SetStaticRatingEnabled(false)
    screen.AllowUpdates(true)
    if item <> invalid and type(item) = "roAssociativeArray"
        screen.SetContent(item)
    endif
    screen.Show()

    while true
      msg = wait(0, screen.GetMessagePort())
      if type(msg) = "roSpringboardScreenEvent"
        if msg.isScreenClosed()
          exit while
        else if msg.isButtonPressed()
          if msg.GetIndex() = 1
            res = DeleteItem(item)
            if (res = true) then
              return -1
            end if
          end if
        endif
      endif
    end while
end function

REM  /*------------------------------------------------- SelectSubtitle -----
REM  |  Function SelectSubtitle
REM  |
REM  |  Purpose:
REM  |      Presents the user with a screen allowing users to select which
REM  |       subtitle source to use, or not load any subtitles
REM  |
REM  |  Parameter(s):
REM  |      subtitles (IN)
REM  |              An array of subtitle items(?)
REM  |
REM  |      screenshot (IN)
REM  |              A screenshot to display adjacent to the subtitle listings
REM  |
REM  |  Returns:
REM  |      subtitle_index that was selected by the user; 0 is don’t load any subtitles
REM  *-------------------------------------------------------------------*/

function SelectSubtitle(subtitles as object, screenshot)
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)
    screen.SetDescriptionStyle("video")
    screen.ClearButtons()
    screen.AddButton(0, "Don't load any subtitles")
    counter = 1
    lang_num = 1
    language = ""
    for each subtitle in subtitles["subtitles"]
      if subtitle.language <> invalid
        if subtitle.language <> language and lang_num <> 1
          lang_num = 1 ' TODO this looks like a bug forcing all languages to English...
        end if
        language = subtitle.language
      	screen.AddButton(counter, language + " "+lang_num.tostr())
      else
	     screen.AddButton(counter, "Unknown language")
      end if
      counter = counter + 1
      lang_num = lang_num + 1
    end for

    screen.SetStaticRatingEnabled(false)
    screen.AllowUpdates(true)

    if counter <> 1
      item = {
        title: "Available Subtitles"
        ContentType: "episode"
        SDPosterUrl: screenshot
      }
      screen.SetContent(item)
    end if
    screen.Show()
    while true
      msg = wait(0, screen.GetMessagePort())
      if type(msg) = "roSpringboardScreenEvent"
        if msg.isScreenClosed()
          exit while
        else if msg.isButtonPressed()
          subtitle_index = msg.GetIndex()
          return subtitle_index
        endif
      endif
    end while

end function

REM /*------------------------------------------------- GetStartFrom -----
REM |  Function GetStartFrom
REM |
REM |  Purpose:
REM |      Gets the starting position in ms for the selected video file
REM |       if it was saved from the last playback
REM |
REM |  Parameter(s):
REM |      args (IN)
REM |              The playback object
REM |
REM |  Returns:
REM |      ms in time (int) to seek into playback to resume playing
REM *-------------------------------------------------------------------*/

function GetStartFrom(args as object)
    if m.current_id <> invalid and args["ID"].toint() <> m.current_id
      m.start_from = invalid
    end if
    if args.DoesExist("StartFrom") = false
      return 0
    end if

    if args["StartFrom"] <> 0
      if m.start_from = invalid
        return args["StartFrom"]
      else
        return m.start_from
      end if
    else if args["StartFrom"] = 0 and m.start_from <> invalid
        return m.start_from
    else
        return 0
    end if
end function
