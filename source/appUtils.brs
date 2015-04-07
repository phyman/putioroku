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
