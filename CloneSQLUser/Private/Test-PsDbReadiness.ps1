<#
.Synopsis
This funtion verifies the readiness of a SQL Server database to be accessed.

.Description
This funtion verifies the readiness of a SQL Server database to be accessed.  In order for a database to be accessed it must first be 
"online".  Though that may sound silly, there are many states a database can be in other than offline or online.

This function verifies that the databases contained in the -Databases string array parameter are all in the "online" state.  If they are, the function 
returns null, otherwise it returns a string array of the database names that are NOT "online".

The purpose of this function is to assure that all databases may be acted upon prior to proceeding with any database processing rather than 
discovering a database that can't be taken offline during the processing phase.

.Parameter ServerInstance
This is the name of the server that will receive the snap mount.

.Parameter Databases
This string array contains a list of the databases that exist on the server specified in the -ServerInstance parameter.  This is needed
because each database will have to be searched for relevent permissions.

.Parameter Silent
This switch determines whether the function simply returns a list of the database that are offline, or outputs that list as a text message to the
standard out device.  If -Silent is included in the function call, the function will simply return an array of the databases that failed the 
online test.  This makes the function useful as a source of offline database information for other functions.  If -Silent is not included, the
function will display a text message to the standard out device making it useful as a simple test and report.

.Example
.
Get-Disable-SQLLogin `
    -ProtectionGroup 'DynDB1' `
    -DestServer 'spf-sv-biqadb1' `
    -Enable "yes"

This will enable all logins associated with the protection group "DynDB1" and the destination server "spf-sv-biqadb1".

.Example
.
Test-DBReadiness `
    -DestServer 'spf-sv-bidevdb1' `
    -Databases ('FACETS', 'FACETSxc', 'FACETSar')

This will query the "spf-sv-bidevdb1" SQL Server to verify that all three databases ('FACETS', 'FACETSxc', 'FACETSar') are online.  If any are
offline, Test-DBReadiness will return a string array containing thos database names.
#>
function Test-PsDbReadiness {
    [CmdletBinding()]

    Param(
        [Parameter (Mandatory = $true)]
        [string] $SourceServer
        ,
        [Parameter (Mandatory = $true)]
        [string[]] $Databases
        ,
        [Parameter (Mandatory = $false)]
        [switch] $Silent
        )

    Write-Verbose 'Verifying database readiness...'

    # Databases is an array of database names.  
    # We'll check each individually to see if it exists.  (Not the most efficient algorithm but the easiest on to implement for the moment.)
    $db_list = $Databases.split(',').Trim()

    # Make sure all databases exist.
    foreach ($db in $db_list) {
        $sql = "select name from master.sys.databases where name = '$db'"
        $dbname = invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database "master" -Query $sql
        if (!$dbname) {
            throw "Unable to find a database matching database list member: $db)"
            }
        }
        
    # Make sure all of the databases are online.
    $db_in_clause = $Databases -join "', '"
    $sql = "select name from master.sys.databases where upper(state_desc) <> 'ONLINE' and name in ('$db_in_clause')"

    try {
        $not_ready = (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database "master" -Query $sql).name
        if ($not_ready) {
            if (!$Silent) {
                Write-Output "--> One or more of the specified databases is not ready to be taken offline!"
                foreach( $db in $not_ready) {
                    Write-Output "----> Offline: $($db)"
                    }
                }
            else {
                $not_ready
                }
            }
        else {
            if (!$Silent) {Write-Output "Databases are ready for processing."}
            }
        }
    catch {
        throw "Error executing 'Invoke-SqlCmd': $_"
        }
    }
