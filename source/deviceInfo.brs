REM /*------------------------------------------------- GetDeviceESN -----
REM |  Function GetDeviceESN
REM |
REM |  Purpose:
REM |      Reads & returns the serial number of the target device
REM |
REM |  Returns:
REM |      Returns the serial number of the target device as a string
REM *-------------------------------------------------------------------*/

function GetDeviceESN()
    return CreateObject("roDeviceInfo").GetDeviceUniqueId()
end function
