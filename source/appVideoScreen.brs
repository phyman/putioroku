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
