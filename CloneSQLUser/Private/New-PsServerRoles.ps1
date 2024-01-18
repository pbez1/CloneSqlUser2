<#
.Synopsis
This funtion formats a header section for the Get-PsUserPermissions function and returns it as a single string.

.Description
This function returns a formatted string that contains a header block whose intent is to describe the server from which the permissions originate,
the source user ($FromUser) whose permissions are to be cloned and the destination user ($ToUser) who will receive the new permissions.

.Parameter ServerInstance
This is the name of the server that will receive the snap mount.

.Parameter Databases
This string array contains a list of the databases that exist on the server specified in the -ServerInstance parameter.  This is needed
because each database will have to be searched for relevent permissions.

.Parameter FromUser
This is the name of the user from which permissions will be cloned.

.Parameter ToUser
This is the name of the user who will receive the new cloned permissions.

.Example
.
Get-Header | out-file -Path "c:\scripts\script_file.sql" -Append

This will append a header block to the "c:\scripts\script_file.sql" file.

.Example
.
Get-Header

This will send a header block to the standard output device, usually the screen.
#>
function New-PsServerRoles {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory=$true)]
        [string] $SourceServer
        ,
        [Parameter(Mandatory=$true)]
        [string] $FromUser
        ,
        [Parameter(Mandatory=$true)]
        [string] $ToUser
        )

    Write-Verbose 'Add Server Roles...'

    $perms = "`n-------------------------------------------------------------------------------`n"
    $perms += "-- Add Server Roles`n"
    $perms += "-------------------------------------------------------------------------------`n"

    try{
        $sql = "
            select
                'alter server role ' + sp.name + ' add member [$ToUser]' script
            from
                sys.server_principals sp
                inner join sys.server_role_members srm on sp.principal_id = srm.role_principal_id
                inner join sys.server_principals sp2 on srm.member_principal_id = sp2.principal_id
            where
                sp.type not in ('G', 'U', 'S')
                and left(sp2.name, 3) not in ('##M', 'NT ')
                and lower(sp2.name) = lower('$FromUser')
            "

        # write-output $sql
        $perms += (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).script + "`n"

        $perms
        }
    catch {
        throw $_
        }
    }
