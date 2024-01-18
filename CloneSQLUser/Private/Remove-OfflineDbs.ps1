<#
.Synopsis
This funtion removes offline database from the database list (since the offline database cannot be accessed).

.Description
Offline databases cannot be interogated for the source user's permissions.  If the offline databases remain in the $databases list,
the scripting engine will throw an error because it can't access the database.  

This function accepts two string arrays: 1) the list of databases on the source server, and 2) a list of those databases that are
offline.  It then builds a new array of only the databases that are online and returns it to the calling process.

.Parameter Databases
This string array contains a list of the databases that exist on the server specified in the -ServerInstance parameter.  This is needed
because each database will have to be searched for relevent permissions.

.Parameter OffLine
This string array contains a list of the databases that are offline and therefor unaccessible by the scripting engine.

.Example
.
Remove-OfflineDbs -Databases "DB_1, DB_2, DB_3, DB_4" -OffLine "DB_2, DB_3"

This will return a new array of database names containing "DB_1, DB_4".
#>
function Remove-OfflineDbs {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory=$true)]
        [string[]] $Databases
        ,
        [Parameter(Mandatory=$true)]
        [string[]] $OffLine
        )

    Write-Verbose 'Removing offline databases...'

    # We must copy the $Databases array to a new array minus the databases in the $offline list.
    # I've not found an easy way to do that so a couple of nested "foreach" loops will have to do for now.
    $new_db_list = @()

    # Loop through each database in the $Databases List and look for matches in the $Offline list.
    foreach($db in $Databases) {
        $in_offline = $false

        foreach($off in $offline) {
            if ($off -eq $db) {
                $in_offline = $true
                break
                }
            }

        # If $in_offline is set to true, the database is listed in the OffLine array and should not 
        # be included in the new list.  Otherwise, add it to the new list.
        if (!$in_offline) {
            $new_db_list += $db
            }
        }

    $new_db_list
    }
