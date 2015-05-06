REM /*------------------------------------------------- SpringboardScreen -----
REM |  Function SpringboardScreen
REM |
REM |  Purpose:
REM |      The item view screen - The Springboard Screen shows detailed
REM |       information about an individual piece of content and provides
REM |       options for actions that may be taken on that content.
REM |      Normal options are: "Play" & "Delete"
REM |      Exception options: "Try to Play" & "Convert to MP4"
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

    ' Button choices labels
    BTN_PLAY        = 1
    BTN_RESTART     = 2

    BTN_TRY_TO_PLAY = 1
    BTN_CONVERT     = 2

    BTN_SUBTITLES   = 3
    BTN_DELETE      = 4

    ' Response codes
    SUCCESS = 200

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
          if (code = SUCCESS) then
            result = ParseJSON(msg.GetString())
            if (result["mp4"]["status"] = "NOT_AVAILABLE") then
              screen.AddButton(BTN_TRY_TO_PLAY, "Try to play")
              screen.AddButton(BTN_CONVERT, "Convert to MP4")
            else if (result["mp4"]["status"] = "COMPLETED") then
              screen.AddButton(BTN_PLAY, "Play")
            else if (result["mp4"]["status"] = "CONVERTING")
              screen.AddButton(BTN_TRY_TO_PLAY, "Try to play")
              percent_done = result["mp4"]["percent_done"]
              item.Description = "Converting to MP4...  "+percent_done.tostr()+"%"
              'TODO: On this screen the "Try to play" button is displayed, but should it be??
            else if (result["mp4"]["status"] = "IN_QUEUE")
              screen.AddButton(BTN_TRY_TO_PLAY, "Try to play")
              item.Description = "In queue, please wait..."
            end if
          end if
        else if (event = invalid)
          request.AsyncCancel()
          screen.AddButton(BTN_TRY_TO_PLAY, "Try to play")
          screen.AddButton(BTN_CONVERT, "Convert to MP4")
        end if
      end if
    else ' This is a video
      if (item.DoesExist("nonVideo") = false) then
        screen.AddButton(BTN_PLAY, "Play")
        screen.AddButton(BTN_RESTART, "Restart")
      end if
    end if

    if (item.DoesExist("NonVideo") = false) then
        subtitles = invalid
        request   = MakeRequest()
        url       = "https://api.put.io/v2/files/"+item["ID"]+"/subtitles?oauth_token="+m.token
        port      = CreateObject("roMessagePort")
        request.SetMessagePort(port)
        request.SetUrl(url)
        if (request.AsyncGetToString())
          msg = wait(0, port)
          if (type(msg) = "roUrlEvent") then
            code = msg.GetResponseCode()
            if (code = SUCCESS) then
                subtitles = ParseJSON(msg.GetString())
                for each subtitle in subtitles["subtitles"]
                  if (subtitles.default = subtitle.key)
                    screen.AddButton(BTN_SUBTITLES, "Subtitles")
                  endif
                end for
            end if
          end if
        end if
    end if

    ' If allowed, all details screens get a delete button
    if (m.delete_allowed <> "false")
      screen.AddButton(BTN_DELETE, "Delete")
    end if
    
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

    subtitle_index    = invalid
    WAITING_FOR_USER  = true

    while (WAITING_FOR_USER)
      msg = wait(0, screen.GetMessagePort())
      if type(msg) = "roSpringboardScreenEvent"
        if msg.isScreenClosed()
          print "DetailsScreen: ScreenClosed"
          exit while
        else if msg.isButtonPressed()
          btnIndex = msg.GetIndex()
          print "DetailsScreen: button pressed " btnIndex

          if (btnIndex = BTN_PLAY or btnIndex = BTN_RESTART)
            if subtitle_index = invalid
              subtitle = subtitles.default
            else if subtitle_index = 0
              'Ayni scopeda degismis olabilir bu degisken. o yuzden tekrar ediyoruz'
              subtitle = invalid
            else
              subtitle = subtitles["subtitles"][subtitle_index-1]["key"]
            end if

            if btnIndex = BTN_PLAY
              'Play the video
              DisplayVideo(item, subtitle)
            else
              ? "Restart the video from the beginning"
              DisplayVideo(item, subtitle, true)
            end if

          else if btnIndex = BTN_CONVERT
            ConvertToMp4(item)

          else if btnIndex = BTN_SUBTITLES
            tmp = SelectSubtitle(subtitles, item.SDPosterUrl)
            if tmp <> invalid
              'selectsubtitle invalid ya da 0, 1, 2... seklinde bir sonuc donuyor'
              'default subtitle secimi yapilan durumla karismamasi icin burdaki invalidi dikkate almiyoruz'
              'geri ok tusuyla hicbir sey yapmadan geri donulurse invalid donuyor'
              subtitle_index = tmp
            end if
          else if btnIndex = DELETE
            res = DeleteItem(item)
            if (res = true) then
              return -1
            end if
          end if
        endif ' msg.isButtonPressed()
      endif
    end while
end function
