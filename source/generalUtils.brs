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
    print "RegRead"
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
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
    print "RegWrite"
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, val)
    sec.Flush() 'commit it'
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
REM |
REM |      If the section is invalid, it creates it, then deletes the key
REM |       BUT, there doesn’t seem to be any reason to do this...
REM |       QED this should be changed to just return if the section is invalid
REM |       to begin with...
REM |
REM *-------------------------------------------------------------------*/

function RegDelete(key, section=invalid)
    print "RegDelete"
    ' TODO check and see if this can't just return if section is invalid coming in
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    sec.Delete(key)
    sec.Flush()
end function
