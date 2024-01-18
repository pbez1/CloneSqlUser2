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
function New-PsUserSchemaPermissions {
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

    Write-Verbose "Add user's schema permissions..."

    $perms = "`n-------------------------------------------------------------------------------`n"
    $perms += "-- Add user's schema permissions`n"
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
            $user_is_present = (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database $database -Query $sql).is_present

            if ($user_is_present) {
                $sql = "select 'use [$database]' + char(13) + char(10) script"
                $perms += (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).script

                $sql = "
                    use [$database]
                    select 'use [$database]' + char(13) + char(10)
                    select 
                        lower(state_desc) + ' ' +  permission_name + ' on SCHEMA::' + schema_name(major_id) + ' to [' + '$ToUser' + ']' + char(13) + char(10) script
                    from 
                        $database.sys.database_permissions AS PERM
                    where
                        class_desc = 'SCHEMA'
                        and user_name(grantee_principal_id) = '$FromUser'
                    "

                # write-output $sql
                $perms += (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).script
                }
            }

        $perms
        }
    catch {
        throw $_
        }
    }
