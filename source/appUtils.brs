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
    print "--- GetStartFrom::Current Id: "m.current_id
    if (m.current_id <> invalid and args["ID"].toint() <> m.current_id)
      m.start_from = invalid
    end if
    if (args.DoesExist("StartFrom") = false)
      return 0
    end if

    if (args["StartFrom"] <> 0)
      if m.start_from = invalid
        return args["StartFrom"]
      else
        return m.start_from
      end if
    else if (args["StartFrom"] = 0 and m.start_from <> invalid)
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
