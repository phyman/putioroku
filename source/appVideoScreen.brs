REM /*------------------------------------------------- DisplayVideo -----
REM |  Function DisplayVideo
REM |
REM |  Purpose:
REM |      Play the selected video
REM |
REM |  Parameter(s):
REM |      item (IN)
REM |              Video items item such as Title, ImageUrl, ID, playhead index (StartFrom)
REM |
REM |      subtitle (IN)
REM |              Selected subtitle option
REM *-------------------------------------------------------------------*/

Function DisplayVideo(item as object, subtitle, do_restart = false)

    ' response codes
    PRECONDITION_FAILED   = 412

    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    bitrates      = [0]
    qualities     = ["HD"]
    StreamFormat  = "mp4"
    title         = item["title"]
    urls          = [item["url"]]

    print "Displaying video: " title

    if type(item["url"]) = "roString" and item["url"] <> "" then
        urls[0] = item["url"]
    end if
    if type(item["StreamFormat"]) = "roString" and item["StreamFormat"] <> "" then
        StreamFormat = item["StreamFormat"]
    end if
    videoclip                 = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates  = bitrates
    videoclip.StreamUrls      = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat    = StreamFormat
    videoclip.Title           = title
    if (m.subtitle_on = "on")
      if subtitle <> invalid
        videoclip.SubtitleUrl = "https://api.put.io/v2/files/"+item["ID"]+"/subtitles/"+subtitle+"?oauth_token="+m.token
      end if
    end if

    if (do_restart)
      videoclip.PlayStart = 0
    else
      videoclip.PlayStart = GetStartFrom(item)
    end if

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
              m.current_id = item["ID"].toint()
              if (currentpos <> 0)
                request = MakeRequest()
                url = "https://api.put.io/v2/files/"+item["ID"]+"/start-from/set?oauth_token="+m.token
                port = CreateObject("roMessagePort")
                request.SetMessagePort(port)
                request.SetUrl(url)
                if (request.AsyncPostFromString("time="+currentpos.tostr()))
                  event = wait(0, port)
                  code = event.GetResponseCode()
                  ? "VideoScreen response code " code
                  if (code = PRECONDITION_FAILED)
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
end Function
