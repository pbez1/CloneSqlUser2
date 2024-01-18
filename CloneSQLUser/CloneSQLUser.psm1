#Requires -Version 5.1
#Requires -Modules @{ModuleName = 'SQLSERVER'; ModuleVersion = "22.0.59"}

#----------------------------------------------------------------------------------------
#                                 Module: CloneSQLUser.psm1
#----------------------------------------------------------------------------------------

#region Initialize_Module
# Specify the name of the module.
$ModuleName = 'CloneSQLUser'

# PowerShell defaults to TSL 1.0.  Why?  Who knows.  TLS 1.0 pretty much went away around 
# 2018.  In any case, the call to any REST interface may fail (depending on the host
# server) without the following line of code.  As you might surmise, it sets TLS at # 1.2.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ScriptRoot must contain the path where this module can be found.  
$ScriptRoot = $PSScriptRoot
if (!$ScriptRoot) {throw "`$ScriptRoot is empty or null.  Unable to determine the location of this module in the file system."}

# Establish this module file's location and read the configuration parameters (if any) from the associated local JSON file.
$ModuleJSON = "$ScriptRoot\$ModuleName.json"

if (Test-Path -Path $ModuleJSON) {$conf_parms = get-content -Path $ModuleJSON | ConvertFrom-Json}
else {throw "Can't find '$ModuleName.json' file.  $_"}

# Set global variables.
# Create the global variables.  Create a global variable for eacy element in the JSON file.
# Get the JSON property names.  These will be the global variable names.
$var_names = ($conf_parms | Get-Member -MemberType NoteProperty).Name
foreach ($var_name in $var_names) {
    # Eliminate JSON "comment" entries.
    if ('_' -ne $var_name.Substring(0,1)) {
        # Get the value of the conf_parms.$var_name object member.
        $var_value = ($conf_parms.PSObject.Properties | 
            Where-Object {$_.name -eq $var_name} | 
            Select-Object value).value

        # Remove the variable if it already exists.
        if (Get-Variable -Name $var_name -ErrorAction SilentlyContinue) {
            Remove-Variable -Name $var_name -Scope Global
            }

        # Create a new variable of Global scope.
        New-Variable -Name $var_name -Value $var_value -Scope Global
        }
    }

# Set any additional parameters for the Invoke-SqlCmd command.
# The JSON file must contain an array called "SqlCmdParms" if this hashtable is to be populated.
# This hashtable will be used to include any additional parameters to all "Invoke-SqlCmd" calls.
$global:sql_parms = @{}
if ($conf_parms.SqlCmdParms) {
    foreach ($parm in $conf_parms.SqlCmdParms) {
        # Add the parameter to the Invoke-SqlCmd splat array.
        switch ($parm.Split('=')[1]) {
            "True" {$sql_parms.Add(($parm.split("="))[0], $true)}
            "False" {$sql_parms.Add(($parm.split("="))[0], $false)}
            Default {$sql_parms.Add(($parm.split("="))[0], ($parm.split("="))[1])}
            }
        }
    }
#endregion Initialize_Module

#----------------------------------------------------------------------------------------
#-- Load the module functions.
#----------------------------------------------------------------------------------------
#Get public and private function definition files.
$Public  = @(Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue)

# Dot source the files into this module.
Foreach($import in @($Public + $Private)) {
    try {
        . $import.fullname
        }
    catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
        }
    }

# Export Public functions
Export-ModuleMember -Function $Public.Basename
