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
function New-PsServerLevelPermissions {
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

    Write-Verbose 'Add Server Level Permissions...'

    $perms = "`n-------------------------------------------------------------------------------`n"
    $perms += "-- Add Server Level Permissions`n"
    $perms += "-------------------------------------------------------------------------------`n"

    try{
        $sql = "
            select
                'use [master]' + char(13) + char(10) +    
                'if not exists (' + char(13) + char(10) + 
                '        select 1 ' + char(13) + char(10) +
                '        from ' + char(13) + char(10) +    
                '            sys.server_permissions sp1' + char(13) + char(10) +
                '            left outer join sys.server_principals sp3 on sp1.grantee_principal_id = sp3.principal_id' + char(13) + char(10) +
                '        where ' + char(13) + char(10) +
                '            sp1.type = ''' + sp.type + ''' and ' + char(13) + char(10) +
                '            lower(sp3.name) = lower(''$ToUser'')) begin' + char(13) + char(10) +
                case
                    when sp.state = 'G' then '    grant '
                    when sp.state = 'D' then '    deny '
                    when sp.state = 'R' then '    revoke '
                    else '    >>> ERROR <<<'
                    end +
                sp.permission_name + ' to [' + ('$ToUser' collate database_default) + ']' +
                case
                    when state = 'W' then ' with grant option'
                    else ''
                    end + char(13) + char(10) +
                '    end' + char(13) + char(10) script
            from
                sys.server_permissions sp
                left outer join sys.server_principals spr on sp.grantee_principal_id = spr.principal_id
            where
                spr.type in ('G', 'U', 'S')
                and left(spr.name, 3) not in ('##M', 'NT ')
                and lower(spr.name) = lower('$FromUser') collate database_default
            order by
                spr.name,
                sp.type
            "

        # write-output $sql
        $perms += (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).script

        $perms
        }
    catch {
        throw $_
        }
    }
