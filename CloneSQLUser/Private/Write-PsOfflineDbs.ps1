<#
.Synopsis
This funtion simple writes a text message to the standard output device stating that the specified offline databases are offline and will be skipped.

.Description
Offline databases cannot be interogated for the source user's permissions.  This function accepts a list of offline databases and posts a message
to the standard output device noting that the databases are offline and will be skipped.

.Parameter OffLine
This string array contains a list of the databases that are offline and therefor unaccessible by the scripting engine.

.Example
.
Write-PsOfflineDbs -OffLine $offline

This will list the offline databases on the standard out device (usually the user's monitor screen).

#>
function Write-PsOfflineDbs {
    [cmdletbinding()]
    
    param(
        [Parameter(Mandatory=$false)]
        [String[]] $OffLine
        )

    if ($OffLine) {
        foreach ($off in $OffLine) {
            Write-Output "--The [$off] database is not available and will be skipped!"
            }

        Write-Output "`n"
        }
    }
