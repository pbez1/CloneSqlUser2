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
function New-PsCreateSchemas {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory=$true)]
        [string] $SourceServer
        ,
        [Parameter(Mandatory=$true)]
        [string[]] $Databases
        ,
        [Parameter(Mandatory=$true)]
        [string] $FromUser
        ,
        [Parameter(Mandatory=$true)]
        [string] $ToUser
        )

    Write-Verbose "Add User's Schemas..."

    $perms = "`n-------------------------------------------------------------------------------`n"
    $perms += "-- Add User's Schemas`n"
    $perms += "-------------------------------------------------------------------------------`n "


    try{
        foreach ($database in $Databases) {
            $user_is_present = $null

            # Verify if the user has permissions on any schema.
            $sql = "
                select 1 is_present 
                from $database.sys.database_permissions perm 
                where 
                    perm.class_desc = 'SCHEMA' 
                    and lower(user_name(perm.grantee_principal_id)) = lower('$FromUser')
                "
            $user_is_present = (Invoke-Sqlcmd @sql_parms -ServerInstance $SourceServer -Database $database -Query $sql).is_present

            if ($user_is_present) {
                $sql = "
                    use [$database]
                    select 
                        'use [$database]' + char(13) + char(10) +
                        'if not exists (select 1 from $database.sys.schemas s1 where s1.schema_id = ' + convert(varchar(30), s.schema_id) + ') begin' + char(13) + char(10) +
                        '    create schema [' + s.name + '] authorization [' + prn.name + ']' + char(13) + char(10) +
                        '    end' + char(13) + char(10) script
                    from 
                        $database.sys.database_permissions perm
                        inner join $database.sys.database_principals prn on prn.principal_id = perm.grantee_principal_id
                        inner join $database.sys.schemas s on perm.major_id = s.schema_id
                    where 
                        prn.is_fixed_role = 0 
                        and s.name not in ('dbo', 'guest', 'INFORMATION_SCHEMA', 'sys')
                        and perm.grantee_principal_id = user_id('$FromUser')
                    group by
	                    s.schema_id,
                        s.name,
                        prn.name
                    "

                # write-output $sql
                $perms += (Invoke-Sqlcmd @sql_parms -ServerInstance $SourceServer -Database $database -Query $sql).script
                }
            }

        $perms
        }
    catch {
        throw $_
        }
    }
            