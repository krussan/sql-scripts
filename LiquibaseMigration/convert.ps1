param([Parameter(Mandatory=$true)][string]$Server,
	[string]$Database,
	[string]$ListPackages,
	[Parameter(Mandatory=$true)][string]$GroupId,
	[string]$DbUser,
	[string]$DbPass)

. ".\liquibase.ps1"
.\scriptAllObjects.ps1 $Server $Database "src" $DBUser $DBPass

buildPackages $ListPackages "build" $GroupId "src" ""
	