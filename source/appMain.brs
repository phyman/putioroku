function Main()
  InitTheme()
  m.g = Init_Const_Globals()
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
  ' print "----==== Main subtitle setting is " m.subtitle_on
  initLandingScreen(facade)
end function


' Function Init_State_Vars() As Object
'     print "100 - Begin - Init_State_Vars"

'     o = CreateObject("roAssociativeArray")
'     o.WAITING_FOR_USER_INPUT = true

'     return o

' end Function

' /*------------------------------------------------- Function Name -----
' |  Function Function Name
' |
' |  Purpose:
' |      Explain what this does for the program, and how it does it
' |
' |  Returns:
' |      if this function sends back a value via the return
' |      mechanism, describe the purpose of that value here
' *-------------------------------------------------------------------*/

Function Init_Const_Globals() As Object
    print "100 - Begin - Init_Const_Static_Globals"

    o = CreateObject("roAssociativeArray")
    o.state = {
      WAITING_FOR_USER_INPUT: true
    }
    o.btn_label = {
      PLAY:         1
      RESTART:      2
      TRY_TO_PLAY:  3
      DELETE:       4
    }
    o.response_code = {
      SUCCESS: 200
    }

    print "200 - End - Init_Const_Static_Globals"
    return o
End Function


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

