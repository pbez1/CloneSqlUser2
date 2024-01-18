<#
.Synopsis
This funtion returns a full file path name (consisting of path and file name) from the parameters provided.

.Description
Accepts an output path (sans file name), a proposed file name and the FromUser, then creates a full file path name consisting of the
file name and output path.  This full file name can then be used to specify a file to read or write to.

If -ServerCount is greater than 1 then the user will need multiple filenames and this function will be called more than once.  Because
of this, the proposed file name (-FileName) will be ignored and a default name will be created and returned in its place.

.Parameter ServerInstance
This is the name of the server that will receive the snap mount.  This parameter can accept a list of servers separated by a comma.  Permissions from
each server will be returned and if an -OutputPath parameter is provided the output will be written to separate files.  (Note, if multiple servers are
specified, the -FileName parameter is ignored and default file names are used.)

.Parameter FromUser
This is the name of the user from which permissions will be cloned.

.Parameter OutputPath
This is the name of the user from which permissions will be cloned.

.Parameter FileName
This is the name of the user who will receive the new cloned permissions.  (Note: this parameter is only used if the user supplies only one SQL Server Instance
in the -ServerInstance parameter)

.Parameter ServerCount
This is a count of the number of file names the user will need.  (This function will be called once for each file name.)  If its value is greater than one
then the user will need more than one file name.  In that case the proposed -FileName parameter value is ignored and a default file name will be returned in
its place.

.Example
.
New-PsFilePath `
    -ServerInstance 'spf-ssis1' `
    -FromUser 'pacificsource\e0001' `
    -OutputPath 'c:\Output' `
    -FileName 'Clone_Output.sql' 

This will return the following full file path: 'c:\Output\Clone_Output.sql'

.Example
.
Assume the date is: September 9, 2021 and the time is 5:15pm 

New-PsFilePath `
    -ServerInstance 'spf-ssis1' `
    -FromUser 'pacificsource\e0001' `
    -OutputPath 'c:\Output' `
    -FileName 'Clone_Output.sql' `
    -ServerCount 2

This will return the following full file path: 'c:\Output\pacificsource_e0001_spf-ssis1_20210916171500.sql'

Note the -FileName parameter has been ignored and the default filename returned in its place.  This is because the ServerCount paramter value is greater than 1.

#>
function New-PsFilePath {
    [cmdletbinding()]

    param(
        [Parameter(Mandatory=$false)]
        [string] $SourceServer
        ,
        [Parameter(Mandatory=$false)]
        [string] $FromUser
        ,
        [Parameter(Mandatory=$false)]
        [string] $OutputPath
        ,
        [Parameter(Mandatory=$false)]
        [string] $FileName
        ,
        [Parameter(Mandatory=$false)]
        [int] $ServerCount = 1
        )
        
    # Construct out-file path if $OutputPath is specified
    if ($OutputPath) {
        # Create a default file name if no file name was specified or if user requested more than one SQL Server.
        if (!$FileName -or ($ServerCount -gt 1)) {
            $dt = Get-Date
            $FileName = "$($FromUser.replace('\','_'))`_$server_instance`_{0:yyyyMMddHHmmss}.sql" -f $dt
            }

        $FilePath = Join-Path -Path $OutputPath -ChildPath $FileName
        
        # If the caller did not supply a filename extension, set it to ".sql"
        if ($FilePath.IndexOf('.') -le -1) {
            $FilePath = "$FilePath.sql"
            }

        # If the $FilePath parameter is not empty, we will write the output to a file.  First
        # we must determine whether to overwrite the file or keep it if it already exists.
        if ($FilePath) {
            # Handle output file name conflicts.
            if (Test-Path -Path $FilePath -PathType Leaf) {
                $yn = Read-Host "The output file already exists.  Would you like to replace it? (Y|N)"
                if ('y' -eq $yn.ToLower()) {
                    Remove-Item -Path $FilePath
                    } 
                else {
                    Write-Output "You've asked that the current file not be overwritten.  Process aborted."
                    return
                    }
                }
            }
            $FilePath
        }
        # Do nothing if the $OutputPath parameter is null
    }
