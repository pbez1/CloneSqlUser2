<#
.Synopsis
This funtion creates a "create user" script that will conditionally create a database user account in the specified database.

.Description
This funtion creates a "create user" script that will conditionally create a database user account based on the account information
in the source user's account.  A script will be created for each database the source user has a user account in.

The resulting script will not create a database user account if one already exists for the user receiving the permissions.

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
New-PsDatabaseUsers `
    -ServerInstance 'sdc-dw' `
    -Databases $databases `
    -FromUser 'pacificsource\e0000' `
    -ToUser 'pacificsource\e0000a'

This will write a script that will create a database user account for the Active Directory account
"pacificsource\e0000a" based on the account information in 'pacificsource\e0000'.  Note that the
$databases array parameteer is preloaded with the list of databases on the server.  This array may
be created manually or may be retrieved with this function call:

$databases = Get-PsDatabaseList -ServerInstance $SourceServer
#>
function New-PsDatabaseUsers {
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

    Write-Verbose 'Add database users...'

    $perms = "`n-------------------------------------------------------------------------------`n"
    $perms += "-- Add database users`n"
    $perms += "-------------------------------------------------------------------------------`n"

    try{
        foreach ($database in $Databases) {
            $user_is_present = $null

            $sql = "select 1 is_present from $database.sys.database_principals where lower(name) = lower('$FromUser')"
            $user_is_present = (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).is_present

            if ($user_is_present) {
                $sql = "
                    use [$database]
                    if exists (select 1 from sys.database_principals where lower(name) = lower('$FromUser')) begin
                            -- Create users for the database if necessary.  Look for NULL's in output.
                            select 
                                coalesce(
                                    'use [$database]' + char(13) + char(10) +
                                    'if not exists (select * from sys.database_principals where lower(name) = lower(''$ToUser'')) begin' + char(13) + char(10) +
                                    '    create user [$ToUser] for login [$ToUser]' + char(13) + char(10) +
                                    '    alter user [$ToUser] with default_schema=[dbo]' + char(13) + char(10) +
                                    '    end',
                                    '--> [$ToUser] not found in sys.syslogins'
                                    ) + char(13) + char(10) script
                            from 
                                sys.database_principals sl
                            where 
                                type <> 'R'
                                and sl.name = '$FromUser'
                            end
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
