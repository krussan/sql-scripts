param([string]$buildType,
	[Parameter(Mandatory=$true)][string]$SrcFolder,
	[Parameter(Mandatory=$true)][string]$Server,
	[string]$Database,
	[string]$ListPackages,
	[string]$SrcDatabaseSuffix,
	[Parameter(Mandatory=$true)][string]$GroupId,
	[string]$DbUser,
	[string]$DbPass)

. ".\liquibase.ps1"
	
if (-not $buildType) {
	$buildType = "Simple"
}
if ($buildType -eq "Simple") {
	buildPackages ("$database|$database" + ":" + "$database") "build" $GroupId $SrcFolder $SrcDatabaseSuffix
}
elseif ($buildType -eq "Package") {
	buildPackages $ListPackages "build" $GroupId $SrcFolder $SrcDatabaseSuffix
}
	