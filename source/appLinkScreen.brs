REM /*------------------------------------------------- ShowLinkScreen -----
REM |  Sub Function ShowLinkScreen
REM |
REM |  Purpose:
REM |      Displays the interactive Link Screen UI to allow users to pair
REM |       their account with the device - this is normally only done once
REM *-------------------------------------------------------------------*/

Function ShowLinkScreen(facade) as Integer
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
end Function

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

