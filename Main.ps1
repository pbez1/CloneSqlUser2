# $databases = Get-PsDatabaseList -ServerInstance 'sdc-sqldw2' #$SourceServer
# Test-PsDbReadiness -ServerInstance 'sdc-sqldw2' -Databases $databases -Silent
# $SourceServer = 'sdc-dw, sdc-dwqa, spf-sv-bidevdb1, sdc-sqldw2, spf-sv-bidbextr, spf-ssis1, spf-ssisqa1, sdc-dwetldv'



Clear-Host

Import-Module .\CloneSQLUser\CloneSQLUser.psm1 -Force

$SourceServer = 'spf-sv-delldb'
$FromUser = 'dba_admin'
$ToUser = 'pacificsource\dba13'

# $SourceServer = 'sdc-sqldbadb'
# $FromUser = 'pb_test'
# $ToUser = 'pacificsource\dba13'
# $OutputPath = 'C:\Users\dba13\Documents\PS\PowerShell\CloneSQLUser\Output'
# $FileName = "pb_test"

Get-PsUserPermissions -?

# Get-PsUserPermissions -SourceServer $SourceServer -FromUser $FromUser -ToUser $ToUser -verbose # -OutputPath $OutputPath -FileName $FileName

# clear-host
# get-help Get-PsUserPermissions -Detailed
