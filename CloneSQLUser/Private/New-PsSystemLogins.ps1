<#
.Synopsis
This funtion creates a "create login" script for the target user ($ToUser).

.Description
This function creates a script that will conditionally create the SQL Server login account for the
user receiving the cloned permissions on the target machine (depending on whether a login for that
user already exists or not).

.Parameter ServerInstance
This is the name of the server that will receive the snap mount.

.Parameter FromUser
This is the name of the user from which permissions will be cloned.

.Parameter ToUser
This is the name of the user who will receive the new cloned permissions.

.Parameter Password
This is an optional parameter used only when creating a SQL Server authenticated account.  It accepts
a clear text password that will be used in the script for creating a new login.  If this parameter is
left blank (or not passed) the resulting script will contain the string "<insert password>" in its
place.  The administrator will have to supply the password in the resulting script.

.Example
.
New-PsSystemLogins `
    -ServerInstance 'sdc-dw' `
    -FromUser 'pacificsource\e0000' `
    -ToUser 'pacificsource\e0000a' `
    -Password 'foo-bar'

This will write a script that will create a login account for the Active Directory account
"pacificsource\e0000a" based on the account information in 'pacificsource\e0000'.  Note that the
Password will be ignored since it is only used when creating a SQL Server authenticated account.

.Example
.
New-PsSystemLogins `
    -ServerInstance 'sdc-dw' `
    -FromUser 'FooAdmin' `
    -ToUser 'BarAdmin' `
    -Password 'foo-bar'

This will write a script that will create a login account for the SQL Server authenticated account
'BarAdmin' based on the account information in 'FooAdmin'.  Note that the Password will be incorporated
into the resulting login creation script such that the script may be executed without editing.

.Example
.
New-PsSystemLogins `
    -ServerInstance 'sdc-dw' `
    -FromUser 'FooAdmin' `
    -ToUser 'BarAdmin'

This will write a script that will create a login account for the SQL Server authenticated account
'BarAdmin' based on the account information in 'FooAdmin'.  Note that no Password was supplied in this
call.  This will result in the "create login" script supplying the string "<insert password>" as the 
password.  This must be edited prior to executing the new login script.
#>
function New-PsSystemLogins {
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
        ,
        [Parameter(Mandatory=$false)]
        [string] $Password
        )

    Write-Verbose 'Add Server Logins...'

    $perms = "`n-------------------------------------------------------------------------------`n"
    $perms += "-- Add Server Logins : Passwords must be entered manually for SQL logins!`n"
    $perms += "-------------------------------------------------------------------------------`n"

    # If a password was passed, include it the script.  Otherwise, insert a placeholder.
    if (!$Password) {$pw = '<insert password>'} else {$pw = $Password}

    try{
        $sql = "
            select 
                'if not exists (select * from master.sys.server_principals where lower(name) = lower(''$ToUser'')) begin' + char(13) + char(10) +
                '    create login [$ToUser] from windows' + char(13) + char(10) +
                '    end'  + char(13) + char(10) script
            from
                sys.server_principals sl
            where 
                (type = 'G' or type = 'U')
                and lower(sl.name) = lower('$FromUser')
            "

        $perms += (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).script
            
        $sql = "
            select 
                'if not exists (select * from master.sys.server_principals where lower(name) = lower(''$ToUser'')) begin' + char(13) + char(10) +
                '    create login [$ToUser] ' + char(13) + char(10) +
                '        with password = ''$pw''' + char(13) + char(10) +
                '            , DEFAULT_DATABASE = [master]' + char(13) + char(10) +
                '            , CHECK_EXPIRATION = OFF' + char(13) + char(10) +
                '            , CHECK_POLICY = OFF' + char(13) + char(10) +
                '    end'  + char(13) + char(10) script
            from 
                sys.server_principals sl
            where 
                type = 'S' 
                and lower(sl.name) = lower('$FromUser')
            "
        $perms += (invoke-sqlcmd @sql_parms -ServerInstance $SourceServer -Database 'master' -Query $sql).script + "`n"

        $perms
        }
    catch {
        throw $_
        }
    }
