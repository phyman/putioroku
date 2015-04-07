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

REM /*------------------------------------------------- CheckSubtitle -----
REM |  Function CheckSubtitle
REM |
REM |  Purpose:
REM |      *UNUSED* - Appears to check if the subtitle file can be found &
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
