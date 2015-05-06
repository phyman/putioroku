REM /*------------------------------------------------- Loading -----
REM |  Function Loading
REM |
REM |  Purpose:
REM |      Displays loading splash screen and “Thinking…” text
REM |
REM |  Returns:
REM |      roImageCanvas object to display
REM *-------------------------------------------------------------------*/

Function Loading() as Object
  canvasItems = [
        {
            url:"pkg:/images/app-icon.png"
            TargetRect:{x:500,y:240,w:290,h:218}
        },
        {
            Text:"Thinking..."
            TextAttrs:{Color:"#66CCFF", Font:"Medium",
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
end Function
