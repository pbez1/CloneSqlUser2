clear-host

# Get-PSRepository
# Install-Module PowerShellGet -Force

# get-module -ListAvailable
# 
# get-command -Module PowerShellGet -PSRepository
# 
# get-help register-psrepository  -detailed

# New-ModuleManifest -Path "C:\users\dba13\Documents\PS\PowerShell\PsPureSnap\PsPureSnapUtils\PsPureSnapUtils.psd1" -ModuleVersion 1.0.1 -Author "Paul Bezanson"

clear-host

$publishModuleSplat = @{
    Repository = 'PSRepo'
    Path = "C:\Users\dba13\Documents\PS\PowerShell\CloneSQLUser\CloneSQLUser"
    }
Publish-Module @publishModuleSplat


# $RepoShare = "\\gruyere\is\DBA\DBAs\DBA Powershell Scripts\PSRepo"

# $repo = @{
    #     Name               = 'PSRepo'
    #     SourceLocation     = $RepoShare
    #     PublishLocation    = $RepoShare
    #     InstallationPolicy = 'Trusted'
    #     }
    # Register-PSRepository @repo

