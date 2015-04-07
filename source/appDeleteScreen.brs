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
