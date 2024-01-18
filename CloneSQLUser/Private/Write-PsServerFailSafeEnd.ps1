function Write-PsServerFailSafeEnd {
    [cmdletbinding()]
    
    param()

    $msg =  "Goto Finish`n"
    $msg += "ErrorMsg:`n"
    $msg += "    print 'Script aborted.'`n"
    $msg += "    goto Quit`n"
    $msg += "Finish:`n"
    $msg += "    print 'Permissions scripting complete.'`n"
    $msg += "Quit:`n"
    
    Write-Output $msg
    }
