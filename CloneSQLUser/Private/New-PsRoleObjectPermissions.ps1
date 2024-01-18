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
function New-PsRoleObjectPermissions {
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

    Write-Verbose "Add role's object level permissions..."

    $perms = "`n-------------------------------------------------------------------------------`n"
    $perms += "-- Add role's object level permissions`n"
    $perms += "-------------------------------------------------------------------------------`n"

    try{
        foreach ($database in $Databases) {
            $role_is_present = $null

            # If a user is a member of a role and that role has permissions, 
            # then those permissions should be created if they're not already present.

            # Get a list of the roles the user is a member of, excluding fixed database roles.
            $sql = "
                select
                    roles.name role
                from
                    sys.database_principals users
                    inner join sys.database_role_members drm on users.principal_id = drm.member_principal_id
                    inner join sys.database_principals roles on roles.principal_id = drm.role_principal_id and roles.type = 'R' and roles.is_fixed_role = 0
                where
                    lower(users.name) <> 'public'
                    and lower(users.name) = lower('$FromUser')
                group by
                    roles.name
                "
            $roles = (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database $database -Query $sql).role

            foreach ($role in $roles) {
                # Verify if the role has permissions on any object.
                $sql = "
                    select 
                        1 is_present
                    from sys.database_permissions perm 
                    where 
                        perm.class_desc = 'OBJECT_OR_COLUMN' 
                        and lower(user_name(perm.grantee_principal_id)) = lower('$role')
                    "
                $perms_are_present = (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database $database -Query $sql).is_present

                if ($perms_are_present) {
                    $perms += "`nuse [$database]`n"
                    $sql = "
                        use [$database]
                        select 
                            lower(state_desc) + ' ' +  permission_name + ' on [' + object_name(major_id) + '] to [$role]' + char(13) + char(10) script
                        from 
                            $database.sys.database_permissions AS PERM
                        where
                            class_desc = 'OBJECT_OR_COLUMN'
                            and lower(user_name(grantee_principal_id)) = lower('$role')
                        "

                    # write-output $sql
                    $perms += (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).script
                    }
                
                $perms += "`n"
                }
            }
            
        $perms
        }
    catch {
        throw $_
        }
    }
