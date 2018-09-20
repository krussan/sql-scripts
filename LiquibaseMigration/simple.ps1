param([Parameter(Mandatory=$true)][string]$Server,
	[Parameter(Mandatory=$true)][string]$Database,
	[Parameter(Mandatory=$true)][string]$GroupId,
	[string]$DbUser,
	[string]$DbPass)

. ".\liquibase.ps1"
.\scriptAllObjects.ps1 $Server $Database "src" $DBUser $DBPass

buildPackages ("$database`|$database`:$database") "build" $GroupId "src" ""
