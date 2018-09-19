
$ListFolderBase = ("Deploy", "Assemblies", "Data", "Database Triggers", "Defaults", "Extended Properties", "Functions", "Rules", "Search property Lists", "Security", "Security\Asymmetric Keys", "Security\Certificates", "Security\Roles", "Security\Schemas", "Security\Symmetric Keys", "Sequences", "Service Broker\Contracts", "Service Broker\Event Notifications", "Service Broker\Message Types", "Service Broker\Queues", "Service Broker\Remote Service Bindings", "Service Broker\Routes", "Service Broker\Services", "Storage", "Storage\Full Text Catalogs", "Storage\Full Text Stoplists", "Storage\Partition Functions", "Storage\Partition Schemes", "Storage\File Groups", "Stored Procedures", "Synonyms", "Tables", "Table triggers", "View triggers", "Types", "Types\User-defined Data Types", "Types\XML Schema Collections", "Views", "ConstraintFunctions")

$ListFolderUsers = ("Security\Users")

$ListRunOnChange = ("Views","Stored Procedures","Functions","Storage\Partition Schemes","Storage\Partition Functions")
$ListDontAddChangeSetForEachDDL = ("Stored Procedures","Functions","Security\Users,Security\Schemas")

function build(
	[string]$database,
	[string]$sourcePath,
	[string]$repoPath) {
	
	write-host "---------------------------------------------------------"
	write-host "Database name :: $database"
	write-host "Source folder :: $sourcePath"
	write-host "Repo path :: $repoPath"
}

function getFolders([bool]$includeUsers) {
	$dirs = $ListFolderBase
	
	if ($includeUsers) {
		$dirs = $dirs + $ListFolderUsers
	}
	
	return $dirs;
}

function init([string]$buildFolderParent,[string]$buildFolder,[string]$groupId,[string]$packageName,[string]$databaseName,[bool]$includeUsers) {
	$dirs = getFolders $includeUsers
	
	Remove-Item -Path $buildFolder -Force -Recurse | out-null
	New-Item -ItemType Directory -Path $buildFolder | out-null
	
	Write-Host "Creating basic files...`n`n"	
	Copy-Item -Path "template_files\deploymaster_redgate.xml" -Destination "$buildFolder\update.xml"
	Copy-Item -Path "template_files\Liquibase.properties.template" -Destination "$buildFolder\liquibase.properties"
	Copy-Item -Path "template_files\run_liquibase.bat" -Destination "$buildFolder"
	Copy-Item -Path "template_files\assembly.xml" -Destination "$buildFolderParent"
	
	(Get-Content template_files\pom.xml).replace("@PACKAGE@", $packageName).replace("@GROUPID@", $groupId).replace("@DATABASENAME@", $databaseName)  | Set-Content -Path "$buildFolder\pom.xml" -Encoding UTF8

	Write-Host "Adding liquibase binaries...`n`n"	
	Copy-Item -Path "template_files\liquibase-app\lib\sqljdbc41.jar" -Destination "$buildFolderParent"
	
	Write-Host "Creating directories and xml structures...`n`n"	
	foreach ($d in $dirs) {
		Write-Host "Creating directory :: $buildFolder\$d"
		New-Item -ItemType Directory -Path "$buildFolder\$d" | out-null
		Copy-Item -Path "template_files\submaster.xml" -Destination "$buildFolder\$d\master.xml"
	}
	
	Get-ChildItem $buildFolderParent -Recurse |
		Where-Object {$_.GetType().ToString() -eq "System.IO.FileInfo"} |
		Set-ItemProperty -Name IsReadOnly -Value $false
}


function buildPackages(
	[string] $listPackages,
	[string] $repoBase,
	[string] $groupId,
	[string] $sourceFolder,
	[string] $sourceFolderSuffix) {
	
	foreach ($s in $listPackages.Split(";")) {
		$arrA = $s.Split("|");
		$modules = "";
		
		if ($arrA.Length -eq 2) {
			$packageName = $arrA[0];
			$databases = $arrA[1];
			
			foreach ($m in $databases.Split(",")) {
				$modules = "<module>$m<\db></module>`r`n   $modules";
			}
			
			(Get-Content template_files\parentpom.xml).replace("@MODULES@", $modules).replace("@PACKAGE@", $packageName).replace("@GROUPID@", $groupId)  | Set-Content -Path "$repoBase\pom.xml" -Encoding UTF8
			
			write-host $modules;
			
			foreach ($db in $databases) {
				write-host $db
				$arrB = $db.Split(":");
				
				if ($arrB.Length -eq 2) {
					$database = $arrB[0];
					$module = $arrB[1];
					
					$sourcePath = "$sourceFolder\$database\$suffix"
					$repoPath = "$repoBase\$packageName\Application\$module\db"
					

					build $database $sourcePath $repoPath
				}
				else {
					write-error "Syntax error in packages"
				}
			}
		}
		else {
			write-error "Syntax error in packages"
		}
	}
}

function getUser([string]$folder) {
	if ($folder -eq "Stored Procedures") {
		$user = "proc"
	}
	elseif ($folder -eq "Functions") {
		$user = "func"
	}
	elseif ($folder -eq "Views") {
		$user = "view"
	}
	else {
		$user = $env.UserName
	}
	
	return $user
}

function createChangesets([string]$result,[bool]$addChangeSetForEachDDL) {
	if ($addChangeSetForEachDDL) {
		# Add changeset comments to each update. Separated with CREATE, ALTER, EXEC or DROP
		# pattern="^(\s*)(CREATE|ALTER|EXEC\s*sp_addextendedproperty|DROP)"
		$regex = New-Object System.Text.RegularExpressions.Regex (`
			"((SET\s+(ANSI_DEFAULTS|ANSI_NULL_DFLT_OFF|ANSI_NULL_DFLT_ON|ANSI_NULLS|ANSI_PADDING|ANSI_WARNINGS|CONCAT_NULL_YIELDS_NULL|CURSOR_CLOSE_ON_COMMIT|QUOTED_IDENTIFIER)\s*(ON|OFF)(\s*GO\s*))*)*?^\s*(CREATE|ALTER|EXEC\s*sp_addextendedproperty|DROP)", `
			[System.Text.RegularExpressions.RegexOptions]::MultiLine `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
			-Or [System.Text.RegularExpressions.RegexOptions]::Singleline)
		$result = $regex.Replace($result, "`n--changeSet $user:Initial-$changeset-{cc} endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:$runonchange`n;$1`n$6");
		
		# Set ANSI_PADDING ON for creation of xml indexes
		$regex = New-Object System.Text.RegularExpressions.Regex (
			"^(\s*)(CREATE\s*PRIMARY\s*XML\s*INDEX)", `
			[System.Text.RegularExpressions.RegexOptions]::MultiLine `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace)
		$result = $regex.Replace($result, "`nSET ANSI_PADDING ON;`n$2");
		
		## Replace the {cc} created above with an iterator
		$count = 1;
		$regex = New-Object System.Text.RegularExpressions.Regex (
			"{cc}", `
			[System.Text.RegularExpressions.RegexOptions]::MultiLine `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace)
		$result = $regex.Replace($result, { Convert.ToString(count++) });
		
		return $result
	}
}

function replaceGoStatements([string]$result) {
	## Replace GO statements with leading and trailing blanks (except GOTO statements)
	$regex = New-Object System.Text.RegularExpressions.Regex ("^\s*GO(?!TO)\s*$", `
		[System.Text.RegularExpressions.RegexOptions]::MultiLine `
		-Or [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		-Or [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace)
	$result = $regex.Replace($result, "GO");
	
	## Replace GOTO statements that have no leading spaces. Liquibase interprets these as GO statements. doh!
	$regex = New-Object System.Text.RegularExpressions.Regex ("^GOTO", `
		[System.Text.RegularExpressions.RegexOptions]::MultiLine `
		-Or [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		-Or [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace)
	$result = $regex.Replace($result, "   GO");
	
	return $result
}

function removeMisc([string]$result,[bool]$includeUsers) {
	## Remove all permissions
	$regex = New-Object System.Text.RegularExpressions.Regex (
			"^\s*GRANT\s*(EXECUTE|SELECT|INSERT|UPDATE|DELETE)\s*ON.*?TO.*?\r?$", `
			[System.Text.RegularExpressions.RegexOptions]::MultiLine `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace)
	$result = $regex.Replace($result, "");
	
	## Remove all role memberships if users are not included
	if (-not $includeUsers) {
		$regex = New-Object System.Text.RegularExpressions.Regex (
				"^\s*EXEC(UTE)?\s*sp_addrolemember\s*N?'.*?'\s*,\s*N?'.*?'\s*\n\s*GO$", `
				[System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-Or [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-Or [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
				-Or [System.Text.RegularExpressions.RegexOptions]::Singleline)
		$result = $regex.Replace($result, "");					
	}
	
	## Remove all USE statements
	$regex = New-Object System.Text.RegularExpressions.Regex (
			"^USE\s+\[?(.*?)\]?\s*GO", `
			[System.Text.RegularExpressions.RegexOptions]::MultiLine `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-Or [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
			-Or [System.Text.RegularExpressions.RegexOptions]::Singleline)
	$result = $regex.Replace($result, "")
	
	return $result
}

function setupRedgateStyle([string]$srcfolder,[string]$buildFolder,[bool]$includeUsers) {
	$cc = 0;
	
	$dirs = getFolders $includeUsers
	foreach ($folder in $dirs) {
		$masterDataFile = "$buildFolder\$folder\master.xml"
		$runonchange = $ListRunOnChange.Contains($folder).ToString().ToLower();
		$addChangeSetForEachDDL = (-not $ListDontAddChangeSetForEachDDL.Contains($folder))
		write-host "`n`nFOLDER :: $folder, RunOnChange :: $runonchange, AddChangeSetForEachDDL :: $addChangeSetForEachDDL"
				
		write-host "MASTER :: $masterDataFile"
		
		$user = getUser $folder
		$header = @"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ext="http://www.liquibase.org/xml/ns/dbchangelog-ext"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.1.xsd
    http://www.liquibase.org/xml/ns/dbchangelog-ext http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-ext.xsd">
	
	<!-- START OF FILE LIST -->
"@
		New-Item -Path $masterDataFile -Value $header -Force | out-null
		
		$sourceFolderItem = "$srcFolder\$folder"
		write-host "Processing folder :: $sourceFolderItem"
		if (Test-Path $sourceFolderItem) {
			foreach ($f in Get-ChildItem -Path $sourceFolderItem -Filter "*.sql") {
				$targetFile = "$buildFolder\$folder\" + $f.Name
				$changeset = $f.BaseName.Replace(".", "-").Replace(" ", "-")
				write-host $changeset
				$source = Get-Content -Path $f.FullName -Encoding UTF8
				$result = $source
				
				$result = replaceGoStatements $result
				$result = createChangesets $result $addChangeSetForEachDDL
				$result = removeMisc $result
				
				## if this is a type where we should not create separate changesets just dump the code with a changeset comment
				if (-not $addChangeSetForEachDDL) {
					$result = "`n--changeSet $user:Initial-$changeset-1 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:$runonchange`n$result"
				}
				
				Set-Content -Path $targetFile -Value $result -Encoding UTF8
			}
		}
	}
	
}

#buildPackages "DBApplication|DBApplication:DBApplication" "repoBase" "com.nordax.db" "C:\git\extern\sql-scripts\scripting\DBApplication\DBApplication" 
#init "build" "build\db\DBApplication" "com.nordax.db" "DBApplication" "DBApplication"
setupRedgateStyle "C:\git\extern\sql-scripts\scripting\build\DBApplication" "build\db\DBApplication" $false
