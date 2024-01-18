<#
.Synopsis
This funtion returns T-SQL code that determines whether the server specified, matches the server executing the code.

.Description
This function creates code that makes sure the spcified server is the server the code is actually executing on.  This
code is added to the beginning of the permissions recreation script to prevent running the code on the wrong server.

.Parameter ServerInstance
The name of the server this code should be executing on.

.Example
.
Write-PsServerFailSafeStart -ServerInstance 'sdc-dwqa'

This will return a T-SQL code fragment that will check that the code is actually running on "sdc-dwqa"
#>
function Write-PsServerFailSafeStart {
    [cmdletbinding()]
    
    param(
        [Parameter(Mandatory=$true)]
        [string] $SourceServer
        )

    $msg =  "if lower(@@servername) <> lower('$SourceServer') begin`n"
    $msg += "    print 'The current server connection (' + @@servername + ') does not match the server specified: $SourceServer'`n"
    $msg += "    goto ErrorMsg`n"
    $msg += "    end`n"

    Write-Output $msg
    }
