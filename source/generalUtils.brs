REM /*------------------------------------------------- RegRead -----
REM |  Function RegRead
REM |
REM |  Purpose:
REM |      Locates and returns the value of the registry key if found
REM |
REM |  Parameter(s):
REM |      key (IN)
REM |              The key to locate and read
REM |
REM |      section (IN)
REM |              The section of the registry where the key should be found;
REM |               default value is ‘invalid' if not provided
REM |
REM |  Returns:
REM |      The key's value if found; invalid otherwise.
REM *-------------------------------------------------------------------*/

function RegRead(key, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then 
      val = sec.Read(key)
      print "RegREAD key: " + key + " val: " + val + " section: " + section
      return val
    end if
    return invalid
end function

REM /*------------------------------------------------- RegWrite -----
REM |  Function RegWrite
REM |
REM |  Purpose:
REM |      Locates and write val(ue) to the registry key if found
REM |
REM |  Parameter(s):
REM |      key (IN)
REM |              The key to locate and write the val(ue) into
REM |
REM |      val (IN)
REM |               The val(ue) to write to the registry's key
REM |
REM |      section (IN)
REM |              The section of the registry where the key should be found;
REM |               default value is ‘invalid' if not provided
REM |
REM *-------------------------------------------------------------------*/

function RegWrite(key, val, section=invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it'
    print "RegWRITE key: " + key + " val: " + val + " section: " + section
end function

REM /*------------------------------------------------- RegDelete -----
REM |  Function RegDelete
REM |
REM |  Purpose:
REM |      Deletes the targeted registry key.
REM |
REM |  Parameter(s):
REM |      key (IN)
REM |              The target registry key to delete
REM *-------------------------------------------------------------------*/

function RegDelete(key, section=invalid)
    ' TODO check and see if this can't just return if section is invalid coming in
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
    print "RegDELETE key: " + key + " val: " + val + " section: " + section
end function

REM /*------------------------------------------------- ExitUserInterface -----
REM |  Function ExitUserInterface
REM |
REM |  Purpose:
REM |      Closes the app & returns user to the dashboard
REM *-------------------------------------------------------------------*/

Sub ExitUserInterface()
    End
End Sub