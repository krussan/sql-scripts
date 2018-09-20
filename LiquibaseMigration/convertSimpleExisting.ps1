param([Parameter(Mandatory=$true)][string]$SrcFolder,
	[Parameter(Mandatory=$true)][string]$Server,
	[string]$Database,
	[string]$ListPackages,
	[Parameter(Mandatory=$true)][string]$GroupId,
	[string]$DbUser,
	[string]$DbPass)

. ".\liquibase.ps1"

buildPackages $ListPackages "build" $GroupId $SrcFolder ""
	