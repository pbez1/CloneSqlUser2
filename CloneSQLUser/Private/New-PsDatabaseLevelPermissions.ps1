function New-PsDatabaseLevelPermissions {
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

    Write-Verbose 'Add Database Level Permissions...'

    $perms = "`n-------------------------------------------------------------------------------`n"
    $perms += "-- Add Database Level Permissions`n"
    $perms += "-------------------------------------------------------------------------------`n"

    try{
        foreach ($database in $Databases) {
            $user_is_present = $null

            if ($database -eq 'HPXR') {
                $s = 'Stop Here'
                }
            # Verify if the user has database level permissions on this database.
            $sql = "
                select 1 is_present 
                from $database.sys.database_permissions perm 
                where 
                    perm.class_desc = 'DATABASE' 
                    and lower(user_name(perm.grantee_principal_id)) = lower('$FromUser')
                "
            $user_is_present = (Invoke-Sqlcmd @sql_parms -ServerInstance $SourceServer -Database $database -Query $sql).is_present

            if ($user_is_present) {
                $sql = "
                    use [$database]
                    select
                        'use [$database]' + char(13) + char(10) +    
                        'if not exists (' + char(13) + char(10) + 
                        '        select 1 ' + char(13) + char(10) +
                        '        from ' + char(13) + char(10) +    
                        '            $database.sys.database_permissions perm1' + char(13) + char(10) +
                        '            left outer join $database.sys.database_principals users1 on perm1.grantee_principal_id = users1.principal_id' + char(13) + char(10) +
                        '        where ' + char(13) + char(10) +
                        '            perm1.type = ''' + ltrim(rtrim(perm.type)) + ''' and ' + char(13) + char(10) +
                        '            lower(users1.name) = lower(''$ToUser'')) begin' + char(13) + char(10) +
                        case
                            when perm.state = 'G' then '    grant '
                            when perm.state = 'D' then '    deny '
                            when perm.state = 'R' then '    revoke '
                            else '    >>> ERROR <<<'
                            end +
                        perm.permission_name + ' to [' + ('$ToUser' collate database_default) + ']' +
                        case
                            when perm.state = 'W' then ' with grant option'
                            else ''
                            end + char(13) + char(10) +
                        '    end' + char(13) + char(10) + char(13) + char(10) script
                    from
                        $database.sys.database_permissions perm
                        left outer join $database.sys.database_principals users on perm.grantee_principal_id = users.principal_id
                    where
                        users.type in ('G', 'U', 'S')
                        and left(users.name, 3) not in ('##M', 'NT ')
                        and perm.class_desc = 'DATABASE'
                        and lower(users.name) = lower('$FromUser') collate database_default
                    order by
                        users.name,
                        perm.type
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
                
  