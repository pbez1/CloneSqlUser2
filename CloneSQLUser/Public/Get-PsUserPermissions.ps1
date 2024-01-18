<#
.Synopsis
This funtion collects all of the permissions granted to the -FromUser in a SQL Server instance and creates a script to grant those same permissions to -ToUser.

.Description
This function gathers all of -FromUser's permission in the specified SQL Server -SourceServer and returns a formatted string that contains a valid SQL script
that will duplicate and grant those permissions to -ToUser on the target server.  

There are a couple of options with regard to where the returned SQL script is written:
1) If the -OutputPath parameter is not supplied, the script will be returned to the standard output device which, in most cases, is the user's monitor screen.
2) If the -OutputPath parameter is supplied, the script will be written to a file (with default file name) at the location described in the -OutputPath 
parameter.  (Note: the -OutputPath should *not* contain the file name.)

If the -FileName parameter is supplied along with the -OutputPath parameter, the resulting script will be written to a file with the specified name in the
location specified by the -OutputPath parameter.  Note: If the user requests permissions from more than one SQL Server, the -FileName parameter is ignored
and default file names are used for each of the resulting files (one for each SQL Server).

.Parameter SourceServer
This is the name of the server that will receive the snap mount.  This parameter can accept a list of servers separated by a comma.  Permissions from
each server will be returned and if an -OutputPath parameter is provided the output will be written to separate files.  (Note, if multiple servers are
specified, the -FileName parameter is ignored and default file names are used.)

.Parameter FromUser
This is the name of the user from which permissions will be cloned.

.Parameter ToUser
This is the name of the user who will receive the new cloned permissions.

.Parameter OutputPath
This is the name of the user from which permissions will be cloned.

.Parameter FileName
This is the name of the user who will receive the new cloned permissions.  (Note: this parameter is only used if the user supplies only one SQL Server Instance
in the -SourceServer parameter)

.Example
.
Get-PsUserPermissions `
    -SourceServer "spf-ssis1" `
    -FromUser 'pacificsource\e0001' `
    -ToUser 'pacificsource\e0002'

This will clone the "pacificsource\e001" user's permissions from the "spf-ssis1" SQL Server and write the resulting script to the user's monitor screen.

.Example
.
Get-PsUserPermissions `
    -SourceServer "spf-ssis1" `
    -FromUser 'pacificsource\e0001' `
    -ToUser 'pacificsource\e0002' `
    -OutputPath 'c:\Output' `
    -FileName 'Clone_Output.sql'

This will clone the "pacificsource\e001" user's permissions from the "spf-ssis1" SQL Server and write the resulting script to a file named "Clone_Output.sql"
in the "c:\Output"
folder. 

.Example
.
Get-PsUserPermissions `
    -SourceServer "spf-ssis1, sdc-dw" `
    -FromUser 'pacificsource\e0001' `
    -ToUser 'pacificsource\e0002' `
    -OutputPath 'c:\Output' `
    -FileName 'Clone_Output.sql'

This will clone the "pacificsource\e001" user's permissions from both the "spf-ssis1" and "sdc-dw" SQL Servers and write the resulting script to two separate
files in the "c:\Output" folder.  Note: The -FileName parameter will be ignored and default names will be supplied because more than one SQL Server instance
was specified.
#>
function Get-PsUserPermissions {
    [cmdletbinding(SupportsShouldProcess)]

    param(
        [Parameter(Mandatory=$true, ParameterSetName='ToDisplay')]
        [Parameter(Mandatory=$true, ParameterSetName='OutPut')]
        [Parameter(Mandatory=$true, ParameterSetName='Apply')]
        [ValidateNotNullOrEmpty()]
        [string[]] $SourceServer
        ,
        [Parameter(Mandatory=$true, ParameterSetName='ToDisplay')]
        [Parameter(Mandatory=$true, ParameterSetName='OutPut')]
        [Parameter(Mandatory=$true, ParameterSetName='Apply')]
        [ValidateNotNullOrEmpty()]
        [string] $FromUser
        ,
        [Parameter(Mandatory=$true, ParameterSetName='ToDisplay')]
        [Parameter(Mandatory=$true, ParameterSetName='OutPut')]
        [Parameter(Mandatory=$true, ParameterSetName='Apply')]
        [ValidateNotNullOrEmpty()]
        [string] $ToUser
        ,
        [Parameter(Mandatory=$true, ParameterSetName='OutPut')]
        [Parameter(Mandatory=$false, ParameterSetName='ToDisplay')]
        [string] $OutputPath
        ,
        [Parameter(Mandatory=$true, ParameterSetName='OutPut')]
        [Parameter(Mandatory=$false, ParameterSetName='ToDisplay')]
        [string] $FileName
        ,
        [Parameter(Mandatory=$true, ParameterSetName='Apply')]
        [Parameter(Mandatory=$false, ParameterSetName='ToDisplay')]
        [string] $DestServer
        ,
        [Parameter(Mandatory=$true, ParameterSetName='Apply')]
        [Parameter(Mandatory=$false, ParameterSetName='ToDisplay')]
        [switch] $ApplyChanges
        ,
        [Parameter(Mandatory=$false, ParameterSetName='Apply')]
        [Parameter(Mandatory=$false, ParameterSetName='ToDisplay')]
        [switch] $ShowScript
        )

    Write-Verbose "Starting user permissions collection..."

    # Verify that if $OutputPath is passed then $FileName also is not null or empty.
    if (![string]::IsNullOrEmpty($OutputPath)) {
        if ([string]::IsNullOrEmpty($FileName)) {
            Write-Output 'The $FileName parameter must contain a value if the $OutputPath parameter is used.'
            return
            }
        }

    # Convert the comma separated list of servers in the $server_instance parameter into an array.
    $server_instances = $SourceServer.Split(',').Trim()

    # If the -ToUser parameter is blank, copy the -FromUser value into -ToUser.
    if(!$ToUser) {$ToUser = $FromUser}

    # Format the $FromUser and $ToUser parameters to make "pacificsource" upper case.
    if (0 -lt $FromUser.IndexOf("\")) {
        $FromUser = "$($FromUser.Split('\')[0].ToUpper())\$($FromUser.Split('\')[1])"
        }
    if (0 -lt $ToUser.IndexOf("\")) {
        $ToUser = "$($ToUser.Split('\')[0].ToUpper())\$($ToUser.Split('\')[1])"
        }
    
    foreach ($server_instance in $server_instances) {
        Write-Output "Processing server: $server_instance"

        try{
            # Get a list of the databases on the source server.
            $databases = Get-PsDatabaseList -SourceServer $server_instance

            # Test the databases on the target server to make sure they're accessible.  If not, display a message under the header
            # listing the databases that will be skipped and adjust the $databases array.
            $offline = Test-PsDbReadiness -SourceServer $server_instance -Databases $databases -Silent
            if ($offline) {
                $databases = Remove-OfflineDbs -Databases $databases -Offline $offline
                }

            # Start processing Screen Output
            if ($PSCmdlet.ShouldProcess('User permissions variables', 'Retrieve permissions')) {
                $header_txt = Get-Header -SourceServer $server_instance -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference 
                $offline_txt = Write-PsOfflineDbs -OffLine $offline -verbose:$verbosepreference
                $failsafe_start_txt = Write-PsServerFailSafeStart -SourceServer $server_instance -verbose:$verbosepreference
                $logins_txt = New-PsSystemLogins -SourceServer $server_instance -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $server_role_txt = New-PsServerRoles -SourceServer $server_instance -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $server_level_txt = New-PsServerLevelPermissions -SourceServer $server_instance -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $create_schemas_txt = New-PsCreateSchemas -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $database_roles_txt = New-PsDatabaseRoles -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $database_users_txt = New-PsDatabaseUsers -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $database_level_txt = New-PsDatabaseLevelPermissions -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $users_schema_perms_txt = New-PsUserSchemaPermissions -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $role_schema_perms_txt = New-PsRoleSchemaPermissions -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $role_obj_txt = New-PsRoleObjectPermissions -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $user_role_member_txt = New-PsUserRoleMembership -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $User_obj_txt = New-PsUserObjectPermissions -SourceServer $server_instance -Databases $databases -FromUser $FromUser -ToUser $ToUser -verbose:$verbosepreference
                $failsafe_end_txt = Write-PsServerFailSafeEnd
                }

            # Collect all of the output into a single variable for display or write to file.
            $script_txt = "{0}{1}{2}{3}{4}{5}{6}{7}{8}{9}{10}{11}{12}{13}{14}{15}" -f 
                $header_txt,
                $offline_txt,
                $failsafe_start_txt,
                $logins_txt,
                $server_role_txt,
                $server_level_txt,
                $create_schemas_txt,
                $database_roles_txt,
                $database_users_txt,
                $database_level_txt,
                $users_schema_perms_txt,
                $role_schema_perms_txt,
                $role_obj_txt,
                $user_role_member_txt,
                $User_obj_txt,
                $failsafe_end_txt

            # Output the results.
            if ($ApplyChanges) {
                invoke-sqlcmd @sql_parms -ServerInstance $DestServer -Database 'master' -Query $script_txt -AbortOnError

                if ($ShowScript) {
                    Write-Output $script_txt
                    }
                }
            else {
                if ($OutputPath) {
                    if ($PSCmdlet.ShouldProcess('File', "Write output")) {
                        # If the caller has provided a value in the $OutputPath parameter, we will write the output to 
                        # a file but first we must determine whether to overwrite the file if it already exists.
                        if (!($FilePath = New-PsFilePath -OutputPath $OutputPath -FileName $FileName -SourceServer $server_instance -FromUser $FromUser -ServerCount $server_instances.Length)) {
                            Write-Output "Exiting."
                            return
                            }
                        else {
                            $script_txt | out-file -FilePath $FilePath
                            }
                        }
                    }
                else {
                    if ($PSCmdlet.ShouldProcess('Calling process', "Return output")) {
                        $script_txt
                        }
                    }
                }

            Write-Output "Scripting Complete"
            }
        catch {
            Write-Output $_
            Write-Output "Continuing with the next database."
            }
        }
    }


