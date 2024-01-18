<#
.Synopsis
This funtion returns the list of databases hosted by the SQL Server specified in the -ServerInstance parameter.

.Description
This function returns an array of database names that exist on the target SQL Server.  This list does not take into account what
state the database in so offline databases may be included.

If the -IncludeSystemDBs switch is included in the function call, the database list will include the system databases. (master msdb,
model, tempdb, distribution)

.Parameter ServerInstance
This is the name of the server that will receive the snap mount.

.Parameter IncludeSystemDBs
This switch determines whether system databases are included in the database list.  If this switch is specifed, system databases will be
included in the database list returned by this function.

.Example
.
Get-PsDatabaseList `
    -ServerInstance 'sdc-dw' `
    -IncludeSystemDBs

This will return a list all the databases on the "sdc_dw" SQL server.  The list will include all of the system databases as well.

.Example
.
Get-PsDatabaseList `
    -ServerInstance 'sdc-dw'

This will return a list all the databases on the "sdc_dw" SQL server excluding the system databases.
#>
function Get-PsDatabaseList {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory=$true)]
        [string] $SourceServer
        ,
        [Parameter(Mandatory=$false)]
        [switch] $IncludeSystemDBs
        )

    if ($IncludeSystemDBs) {
        $sql = "select name from sys.databases"
        }
    else {
        $sql = "select name from sys.databases where name not in ('master', 'model', 'tempdb', 'msdb', 'distribution')"
        }

    try {
        (Invoke-Sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).Name
        }
    catch {
        throw $_
        }
    }
