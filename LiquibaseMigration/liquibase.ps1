#############################################################################
#If Powershell is running the 32-bit version on a 64-bit machine, we 
#need to force powershell to run in 64-bit mode .
#############################################################################
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    write-warning "Y'arg Matey, we're off to 64-bit land....."
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}


#############################################################################
#End
#############################################################################


# param([string]$buildType,
	# [Parameter(Mandatory=$true)][string]$SrcFolder,
	# [Parameter(Mandatory=$true)][string]$Server,
	# [string]$Database,
	# [string]$ListPackages,
	# [string]$SrcDatabaseSuffix,
	# [Parameter(Mandatory=$true)][string]$GroupId,
	# [string]$DbUser,
	# [string]$DbPass)

#Remove-Module SQLPS 
Import-Module -Name SqlServer 
	
#Simple mode
## liquibase.ps1 -SrcFolder c:\src\databases\mydb -Server localhost -Database mydb -GroupId com.mycompany

# could also be written as
## liquibase.ps1 -BuildType "Package" -SrcFolder c:\src\databases -Server localhost -ListPackages "mydb|mydb:mydb" -GroupId com.mycompany

#Package mode (several db's in several packages)
## liquibase.ps1 -BuildType "Package" -SrcFolder c:\src\databases -Server localhost -ListPackages "MyPackage1|MyDbA:ModuleA,MyDbB:ModuleB;MyPackage2|MyDbC:ModuleC" -GroupId com.mycompany

$ListFolderBase = ("Deploy", "Assemblies", "Data", "Database Triggers", "Defaults", "Extended Properties", "Functions", "Rules", "Search property Lists", "Security", "Security\Asymmetric Keys", "Security\Certificates", "Security\Roles", "Security\Schemas", "Security\Symmetric Keys", "Sequences", "Service Broker\Contracts", "Service Broker\Event Notifications", "Service Broker\Message Types", "Service Broker\Queues", "Service Broker\Remote Service Bindings", "Service Broker\Routes", "Service Broker\Services", "Storage", "Storage\Full Text Catalogs", "Storage\Full Text Stoplists", "Storage\Partition Functions", "Storage\Partition Schemes", "Storage\File Groups", "Stored Procedures", "Synonyms", "Tables", "Table triggers", "View triggers", "Types", "Types\User-defined Data Types", "Types\XML Schema Collections", "Views", "ConstraintFunctions")

$ListFolderUsers = ("Security\Users")

$ListRunOnChange = ("Views","Stored Procedures","Functions","Storage\Partition Schemes","Storage\Partition Functions")
$ListDontAddChangeSetForEachDDL = ("Stored Procedures","Functions","Security\Users,Security\Schemas")

function build(
	[string]$database,
	[string]$sourcePath,
	[string]$buildFolderParent,
	[string]$groupId,
	[bool]$includeUsers) {
	
	write-host "---------------------------------------------------------"
	write-host "Database name :: $database"
	write-host "Source folder :: $sourcePath"
	write-host "Build path :: $buildFolderParent"
	write-host "---------------------------------------------------------"
	
	$buildFolder = "$buildFolderParent\db\$database"
	
	init $buildFolderParent $buildFolder $groupId $database $database
	setupRedgateStyle $sourcePath $buildFolder $includeUsers
	handleInvalidObjects $buildFolder
	
	#handleCheckConstraints $buildFolder $server $database
	#handleViewFunctions $buildFolder $server $database
	#handleObjectOrder $buildFolder $server $database
	#extractAllTriggers $buildFolder
	#setupData $buildFolder $server $database
	handleObjectCreation $buildFolder $server $database
}

function getFolders([bool]$includeUsers) {
	$dirs = $ListFolderBase
	
	if ($includeUsers) {
		$dirs = $dirs + $ListFolderUsers
	}
	
	return $dirs;
}

function init([string]$buildFolderParent,[string]$buildFolder,[string]$groupId,[string]$packageName,[string]$databaseName,[bool]$includeUsers) {
	$dirs = getFolders $true
	
	Remove-Item -Path $buildFolder -Force -Recurse | out-null
	New-Item -ItemType Directory -Path $buildFolder | out-null
	
	Write-Host "Creating basic files...`n`n"	
	Copy-Item -Path "template_files\deploymaster_redgate.xml" -Destination "$buildFolder\update.xml"
	Copy-Item -Path "template_files\Liquibase.properties.template" -Destination "$buildFolder\liquibase.properties"
	Copy-Item -Path "template_files\run_liquibase.bat" -Destination "$buildFolder"
	Copy-Item -Path "template_files\assembly.xml" -Destination "$buildFolderParent"
	
	(Get-Content template_files\pom.xml -Encoding UTF8 -Raw).replace("@PACKAGE@", $packageName + "-parent").replace("@GROUPID@", $groupId).replace("@DATABASENAME@", $databaseName)  | Set-Content -Path "$buildFolder\pom.xml" -Encoding UTF8

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
	[string] $buildFolderParent,
	[string] $groupId,
	[string] $sourceFolder,
	[string] $sourceFolderSuffix) {
	
	foreach ($s in $listPackages.Split(";")) {
		$arrA = $s.Split("|");
		$modules = "";
		
		#package|db:module,db:module
		if ($arrA.Length -eq 2) {
			$packageName = $arrA[0];
			$databases = $arrA[1];
			
			foreach ($m in $databases.Split(",")) {
				
			}
			
		
		
			foreach ($db in $databases) {
				write-host $db
				$arrB = $db.Split(":");
				
				if ($arrB.Length -eq 2) {
					$database = $arrB[0];
					$module = $arrB[1];
					
					$modules = "<module>db\$module</module>`r`n   $modules";
					
					$sourcePath = "$sourceFolder\$database$suffix"
					#$buildFolder = "$buildFolderParent\$packageName\Application\$module\db"

					build $database $sourcePath $buildFolderParent $groupId $false
				}
				else {
					write-error "Syntax error in packages"
				}
			}
			
			(Get-Content template_files\parentpom.xml -Encoding UTF8 -Raw).replace("@MODULES@", $modules).replace("@PACKAGE@", $packageName + "-parent").replace("@GROUPID@", $groupId)  | Set-Content -Path "$buildFolderParent\pom.xml" -Encoding UTF8

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
		$user = $env:UserName
	}
	
	return $user
}

function createChangesets([string]$result,[string]$user) {
	
	# Add changeset comments to each update. Separated with CREATE, ALTER, EXEC or DROP
	# pattern="^(\s*)(CREATE|ALTER|EXEC\s*sp_addextendedproperty|DROP)"
	$regex = New-Object System.Text.RegularExpressions.Regex ( `
		"((SET\s+(ANSI_DEFAULTS|ANSI_NULL_DFLT_OFF|ANSI_NULL_DFLT_ON|ANSI_NULLS|ANSI_PADDING|ANSI_WARNINGS|CONCAT_NULL_YIELDS_NULL|CURSOR_CLOSE_ON_COMMIT|QUOTED_IDENTIFIER)\s*(ON|OFF)(\s*GO\s*))*)*?^\s*(CREATE|ALTER|EXEC\s*sp_addextendedproperty|DROP)", `
		([System.Text.RegularExpressions.RegexOptions]::MultiLine `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
		-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
	
	$result = $regex.Replace($result, `
		"`n--changeSet " + $user + ":Initial-$changeset-{cc} endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:$runonchange`n`$1`$6");
	
	
		
	
	# Set ANSI_PADDING ON for creation of xml indexes
	$regex = New-Object System.Text.RegularExpressions.Regex ( `
		"^(\s*)(CREATE\s*PRIMARY\s*XML\s*INDEX)", `
		([System.Text.RegularExpressions.RegexOptions]::MultiLine `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
	$result = $regex.Replace($result, "`nSET ANSI_PADDING ON;`n`$2");
	


	# Replace the {cc} created above with an iterator
	$result = replaceIterator $result
	
	return $result

}

function replaceGoStatements([string]$result) {
	## Replace GO statements with leading and trailing blanks (except GOTO statements)
	$regex = New-Object System.Text.RegularExpressions.Regex ("^\s*GO(?!TO)\s*`$", `
		([System.Text.RegularExpressions.RegexOptions]::MultiLine `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
	$result = $regex.Replace($result, "GO");
	
	## Replace GOTO statements that have no leading spaces. Liquibase interprets these as GO statements. doh!
	$regex = New-Object System.Text.RegularExpressions.Regex ("^GOTO", `
		([System.Text.RegularExpressions.RegexOptions]::MultiLine `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
	$result = $regex.Replace($result, "   GO");
	
	return $result
}

function removeMisc([string]$result,[bool]$includeUsers) {
	## Remove all permissions
	$regex = New-Object System.Text.RegularExpressions.Regex ( `
			"^\s*GRANT\s*(EXECUTE|SELECT|INSERT|UPDATE|DELETE)\s*ON.*?TO.*?\r?`$", `
			([System.Text.RegularExpressions.RegexOptions]::MultiLine `
			-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
	$result = $regex.Replace($result, "");
	
	## Remove all role memberships if users are not included
	if (-not $includeUsers) {
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				"^\s*EXEC(UTE)?\s*sp_addrolemember\s*N?'.*?'\s*,\s*N?'.*?'\s*\n\s*GO`$", `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
				-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
		$result = $regex.Replace($result, "");					
	}
	
	## Remove all USE statements
	$regex = New-Object System.Text.RegularExpressions.Regex ( `
			"^USE\s+\[?(.*?)\]?\s*GO", `
			([System.Text.RegularExpressions.RegexOptions]::MultiLine `
			-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
			-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
	$result = $regex.Replace($result, "")
	
	return $result
}

function replaceJunk([string]$result) {
	# Parse away junk between changesets and creation
	# what about comments?
	$regex = New-Object System.Text.RegularExpressions.Regex ( `
		@"
(
	(
		SET\s+(ANSI_DEFAULTS|ANSI_NULL_DFLT_OFF|ANSI_NULL_DFLT_ON|ANSI_NULLS|ANSI_PADDING|ANSI_WARNINGS|CONCAT_NULL_YIELDS_NULL|CURSOR_CLOSE_ON_COMMIT|QUOTED_IDENTIFIER)
		\s+(ON|OFF)
		(\s*GO)*
		\s*
	)+
)
"@, `
		([System.Text.RegularExpressions.RegexOptions]::MultiLine `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
		-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
	$result = $regex.Replace($result, "`$1`nGO`n");
	
	$regex = New-Object System.Text.RegularExpressions.Regex ( `
		"(--liquibase\sformatted\ssql)(.*?)(--changeSet)", `
		([System.Text.RegularExpressions.RegexOptions]::MultiLine `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
		-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
	$result = $regex.Replace($result, "`$1`n`n`$3");
	
	return $result
}

function replaceStartEnd([string]$result) {
	$regex = New-Object System.Text.RegularExpressions.Regex ( `
			"GO\s*`$", `
			([System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
			-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
	if (-not $regex.IsMatch($result)) {
		$result = "--liquibase formatted sql`n$result`nGO`n"
	}
	else {
		$result = "--liquibase formatted sql`n$result`n"
	}
	
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
				$changeset = $f.BaseName.Replace(".", "-").Replace(" ", "-").Replace("_", "-")
		
				write-host "Processing file $f"
				
				$source = Get-Content -Path $f.FullName -Encoding UTF8 -Raw
				$result = $source
				
				if ($result.length -gt 0) {					
					$result = replaceGoStatements $result
					$result = removeMisc $result
					
					if ($addChangeSetForEachDDL) {				
						$result = createChangesets $result $user
					}
					if (-not $addChangeSetForEachDDL) {
						## if this is a type where we should not create separate changesets just dump the code with a changeset comment
						$result = "`n--changeSet " + $user + ":Initial-$changeset-1 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:$runonchange`n$result"
					}
					
					
					$result = replaceStartEnd $result
					$result = replaceJunk $result
					
					Set-Content -Path $targetFile -Value $result -Encoding UTF8
					Add-Content -Path $masterDataFile -Value ('        <include file="' + $f.Name + '" relativeToChangelogFile="true" />') -Encoding UTF8
				}
			}
		}
		
		$footer = @"
	<!-- END OF FILE LIST -->
</databaseChangeLog>
"@		
		Add-Content -Path $masterDataFile -Value $footer -Encoding UTF8
	}
	
}

function handleInvalidObjectsType([string]$folder,[string]$pattern,[string]$replacement) {

	foreach ($f in Get-ChildItem -Path $folder -Filter "*.sql") {	
		write-host "Invalid objects on :: $f"
		$result = Get-Content -Path $f.FullName -Encoding UTF8 -Raw
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				$pattern, `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
		$result = $regex.Replace($result, $replacement);							
		Set-Content -Path $f.FullName -Value $result -Encoding UTF8
	}
}

function handleInvalidObjects([string]$buildFolder) {
	## The purpose of this target is to replace invalid sql files that starts with ALTER FUNCTION / ALTER PROCEDURE
	handleInvalidObjectsType "$buildFolder\Stored Procedures" "^\s*ALTER\s*PROC(EDURE)?" "CREATE PROCEDURE"
	handleInvalidObjectsType "$buildFolder\Functions" "^\s*ALTER\s*FUNCTION" "CREATE FUNCTION"
}

function handleObjectMove([string]$sqlFile,[string]$sourceFolder,[string]$targetFolder,[string]$server,[string]$database) {
	$sourceFile = "$sourceFolder\master.xml"
	$targetFile = "$targetFolder\master.xml"
	
	Write-Host "HandleObjectMove :: $sourceFile -> $targetFile"
	
	$source = Get-Content -Path $sourceFile  -Encoding UTF8 -Raw
	$target = Get-Content -Path $targetFile  -Encoding UTF8 -Raw

	$rows = Invoke-SqlCmd -ServerInstance $server -Database $database `
		-InputFile "template_files\$sqlFile" `
		-OutputAs DataRows
	
	foreach ($r in $rows) {
		$f = Get-Item ($sourceFolder + "\" + $r.fullName + ".sql")
		
		Write-host "Object Move :: $filename"
		
		if (Test-Path $f.FullName) {
			$filename = $f.Name
			Write-host "... Moving ..."
			Move-Item -Path $f.FullName -Destination $targetFolder

			$regex = New-Object System.Text.RegularExpressions.Regex ( `
					"^\s*\<include\s*file=""$filename"".*?`$", `
					([System.Text.RegularExpressions.RegexOptions]::MultiLine `
					-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
					-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
			$source = $regex.Replace($source, "<!-- $filename Moved to constraint functions -->");		
			
			if (-not $target.Contains($filename)) {		
				$regex = New-Object System.Text.RegularExpressions.Regex ( `
						"^\s*\<\!--\sEND", `
						([System.Text.RegularExpressions.RegexOptions]::MultiLine `
						-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
						-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
				$target = $regex.Replace($target, `
					"	<include file=""$filename"" relativeToChangelogFile=""true"" />`n	<!-- END");		
					
				Write-Host "REPLACE FIRST :: $filename"
			}
		}
	}
	
	Set-Content -Path $sourceFile -Value $source -Encoding UTF8
	Set-Content -Path $targetFile -Value $target -Encoding UTF8
}

function handleCheckConstraints([string]$buildFolder,[string]$server,[string]$database) {
	## The purpose of this target is to move all functions that are part of a check constraint to execute before table creation
	Write-Host "Handle Check Constraints :: $buildFolder"
	
	handleObjectMove `
		"GetCheckConstraints.sql" `
		"$buildFolder\Functions" `
		"$buildFolder\ConstraintFunctions" `
		$server `
		$database
		
}

function handleViewFunctions([string]$buildFolder,[string]$server,[string]$database) {
	## The purpose of this target is to move all functions referenced by views to ConstraintFunctions

	handleObjectMove `
		"GetReferencedFunctionsByView.sql" `
		"$buildFolder\Functions" `
		"$buildFolder\ConstraintFunctions" `
		$server `
		$database
}

function changeObjectOrder([string]$type,[string]$sourceFolder,[string]$sqlFile,[string]$server,[string]$database) {
	Write-Host "Running object order on :: $type"
	
	if (Test-Path $sqlFile) {
		$masterFile = "$sourceFolder\master.xml"
		
		write-host "Modifying $masterfile for order of object creation ..."
		$source = Get-Content -Path $masterFile  -Encoding UTF8 -Raw
		
		
		$rows = Invoke-SqlCmd -ServerInstance $server -Database $database `
			-InputFile $sqlFile `
			-Variable "type=$type" `
			-OutputAs DataRows
			
		$newOrder = "";
		
		# re-arrange order of include tags
		foreach ($r in $rows) {
			$tag = $r.tag
			$objectName = $r.objectName
			
			$filePath = "$sourceFolder\$objectName.sql"
			
			write-host "Checking for file :: $filePath"
			
			if (Test-Path $filePath) {
				$newOrder = "$newOrder`n$tag"
			}
		}
		
		#  check the new generated source and delete all files that are not present in the masterdata
		# foreach ($f in Get-ChildItem -Path $sourceFolderItem -Filter "*.sql") {
			# $filename = $f.FullName
			# write-host "Checking master data for file :: $filename"
			
			# if (
			
		# }
		
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				"\<\!--\sSTART\sOF\sFILE\sLIST\s--\>(.*?)\<\!--\sEND\sOF\sFILE\sLIST\s--\>", `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
				-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
		$source = $regex.Replace($source, "<!-- START OF FILE LIST -->`n$newOrder`n    <!-- END OF FILE LIST -->`n");
		
		Set-Content -Path $masterFile -Value $source -Encoding UTF8
	}
}

function handleObjectOrder([string]$buildFolder,[string]$server,[string]$database) {
	changeObjectOrder "TABLES" "$buildFolder\Tables" "template_files\ChangeOrderOfTableCreation2.sql" $server $database
	changeObjectOrder "VIEW" "$buildFolder\Views" "template_files\ChangeorderOfFunctionAndViews2.sql" $server $database
	changeObjectOrder "FUNCTION" "$buildFolder\Functions" "template_files\ChangeorderOfFunctionAndViews2.sql" $server $database
	changeObjectOrder "ASSEMBLY" "$buildFolder\Assemblies" "template_files\ChangeOrderOfAssemblies.sql" $server $database
}

function replaceIterator([string]$source) {
	$count = 0;
	$regex = New-Object System.Text.RegularExpressions.Regex ( `
		 "{cc}", `
		 ([System.Text.RegularExpressions.RegexOptions]::MultiLine `
		 -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
		 -bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
	while($regex.IsMatch($source)) {
		$count = $count + 1
		$source = $regex.Replace($source, $count, 1)
	}
	
	#$source = $regex.Replace($source, { $count++; return ($count).ToString() });
		
	return $source;
}

function extractTriggers([string]$triggerType,[string]$buildFolder) {
	write-host "Extracting trigger of type :: $triggertype"
	$targetFolder = "$buildFolder\$triggerType triggers"
	$sourceFolder = "$buildFolder\$triggerType" + "s"
	$masterDataFile = "$targetFolder\master.xml"
	$user = $env:UserName
	
	$output = @"
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<databaseChangeLog
    xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:ext="http://www.liquibase.org/xml/ns/dbchangelog-ext"
    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-3.1.xsd
    http://www.liquibase.org/xml/ns/dbchangelog-ext http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-ext.xsd">
	
	<!-- START OF FILE LIST -->
"@	
	foreach ($f in Get-ChildItem -Path $sourceFolder -Filter "*.sql") {
		$filename = $f.FullName
		
		$changeset = $f.BaseName.Replace(".", "-").Replace(" ", "-").Replace("_", "-")
		
		write-host "Extracting triggers from :: $filename"
		$source = Get-Content -Path $filename -Encoding UTF8 -Raw
		
		# remove all liquibase changeset comments from the original file
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				"^--changeset.*?`$", `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
		$source = $regex.Replace($source, "");
		
		# match all triggers up until the next GO statement. be sure to include set options before the trigger
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				@"
(?<total>((SET\s+(ANSI_DEFAULTS|ANSI_NULL_DFLT_OFF|ANSI_NULL_DFLT_ON|ANSI_NULLS|ANSI_PADDING|ANSI_WARNINGS|CONCAT_NULL_YIELDS_NULL|CURSOR_CLOSE_ON_COMMIT|QUOTED_IDENTIFIER)\s+(ON|OFF)(\s*GO\s*))*)^\s*(CREATE\s+TRIGGER)\s+\[?(?<schema>[a-z|A-Z|0-9|_]*)\]?\.\[?(?<object>[a-z|A-Z|0-9|_]*)\]?.*?^GO(?!TO))				
"@, `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
				-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
		foreach ($m in $regex.Matches($source)) {
			# foreach match we have the full trigger in the total variabel, schema and object
			# create the new trigger filename
			$triggerBaseName = $f.BaseName + "-" + $m.Groups["schema"].Value + "." + $m.Groups["object"].Value
			$triggerFilename = "$targetFolder\$triggerBaseName.sql"
			$total = $m.Groups["total"].Value
			
			# write the trigger to file
			$triggerContent = @"
--liquibase formatted sql

--changeSet $user:Initial-$triggerBaseName-0 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:false
$total
					
"@
			Set-Content -Path $triggerFilename -Encoding UTF8 -Value $triggerContent
			
			# Add the file to the masterdata file in the trigger catalog
			$output = $output + "        <include file=""$triggerBaseName.sql"" relativeToChangelogFile=""true"" />`n"
		}
		
		# match all trigger order and move them to separate file
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				"^(?<paramrow>\s*EXEC\s*sp_settriggerorder\s*(N)?'(?<paramfilename>[^']*)'.*?)`$", `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
			
		$triggerOrder = "";
		foreach ($m in $regex.Matches($source)) {
			$paramFilename = $m.Groups["paramfilename"].Value
			$paramFilename = $paramfilename.Replace("[", "").Replace("]", "")
			$paramRow = $m.Groups["paramRow"].Value
			
			$triggerOrder = $triggerOrder + "^n" + $paramRow
		}
		$triggerOrderFilename = $triggerBaseName + "-trigger-order.sql"		
		
		if ($triggerOrder.Length > 0) {
			$content = @"
--liquibase formatted sql

--changeSet $user:Initial-$triggerBaseName-trigger-order-0 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:false
$triggerOrder
"@
			Set-Content -Path "$targetFolder\$triggerOrderFilename" -Value $content -Encoding UTF8
			
			# Add the order file to the masterdata file
			$output = $output + "        <include file=""$triggerOrderFilename"" relativeToChangelogFile=""true"" />`n"
		}
		
		# remove the triggers from the original file 
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				@"
((SET\s*(ANSI_DEFAULTS|ANSI_NULL_DFLT_OFF|ANSI_NULL_DFLT_ON|ANSI_NULLS|ANSI_PADDING|ANSI_WARNINGS|CONCAT_NULL_YIELDS_NULL|CURSOR_CLOSE_ON_COMMIT|QUOTED_IDENTIFIER)\s*(ON|OFF)(\s*GO\s*))*)^\s*(CREATE\s*TRIGGER)\s*\[?([a-z|A-Z|0-9|_]*)\]?\.\[?([a-z|A-Z|0-9|_]*)\]?.*?^GO(?!TO)
"@, `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
				-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
		$source = $regex.Replace($source, "");
		
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				"^(\s*EXEC\s*sp_settriggerorder\s*(N)?'([^']*)'.*?)`$", `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))		
		$source = $regex.Replace($source, "");				
		
		# # redo the changeset comments
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
				@"
((
(SET\s*(ANSI_NULLS|ANSI_DEFAULTS|ANSI_NULL_DFLT_OFF|ANSI_NULL_DFLT_ON|ANSI_NULLS|ANSI_PADDING|ANSI_WARNINGS|CONCAT_NULL_YIELDS_NULL|CURSOR_CLOSE_ON_COMMIT|QUOTED_IDENTIFIER)\s*)
(ON|OFF)\s*
((GO)\s*)*
)*)
\s*(CREATE|ALTER|EXEC\s*sp_addextendedproperty|DROP)(?!_EXISTING)
"@, `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace `
				-bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
		$source = $regex.Replace($source, "`n`n--changeSet " + $user + ":Initial-$changeset-{cc} endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:false`n`$8");
		
		# Replace the ${cc} created above with an iterator
		$source = replaceIterator $source
		
		# rewrite the original file without the triggers
		Set-Content -Path $filename -Value $source -Encoding UTF8
		
	}
}

function extractAllTriggers([string]$buildFolder) {
	extractTriggers "Table" $buildFolder
	extractTriggers "View" $buildFolder
}

function setupData([string]$buildFolder,[string]$server,[string]$database) {
	$dataobjects = ""
	# The purpose of this target is to sort the data files to execute in the correct order according to foreign keys
	foreach ($f in Get-ChildItem -Path "$buildFolder\Data" -Filter "*Data.sql") {
		$datafile = $f.Name
		$schema = $datafile.Subtring(0,$datafile.IndexOf("."))
		$table = $datafile.Substring($datafile.IndexOf(".") + 1, $datafile.Length - $datafile.IndexOf(".") - 10)
		
		write-host "Processing data file $datafile :: $schema :: $table"
		$dataobjects = $dataobjects + "`nINSERT INTO #tables (schemaName, tableName) VALUES ('$schema', '$table');"
		
		(Get-Content template_files\ChangeOrderOfDataScripts.sql -Encoding UTF8 -Raw).replace("@OBJECTS@", $dataobjects) | Set-Content -Path "temp\datascript.sql" -Encoding UTF8
		changeObjectOrder "DATA" "$buildFolder\Data" "temp\datascript.sql" $server $database
	}
}

function fixDataScript([string]$buildFolder) {
	# The purpose of this target is to insert a changeset comment in all data files
	$user = $env:UserName
	
	foreach ($f in Get-ChildItem -Path "$buildFolder\Data" -Filter "*Data.sql") {
		$filename = $f.FullName;
		$changeset = $f.BaseName.Replace(".", "-").Replace(" ", "-").Replace("_", "-")		
		
		write-host "Processing file :: $filename"

		$source = Get-Content -Path $filename -Encoding UTF8 -Raw		
		$regex = New-Object System.Text.RegularExpressions.Regex ( `
			"--liquibase\sformatted\ssql", `
			([System.Text.RegularExpressions.RegexOptions]::MultiLine `
			-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
			-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
		$source = $regex.Replace($source, "--liquibase formatted sql`n`n--changeSet " + $user + ":Initial-${changeset}-1 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:false");		
		
		Set-Content -Path $filename -Value $source -Encoding UTF8		
	}
}

function getCollation([string]$server,[string]$database) {
	$data = Invoke-SqlCmd -ServerInstance $server -Database $database `
		-Query "SELECT collation_name FROM sys.databases WHERE database_id = DB_ID()" `
		-OutputAs DataRow
	
	return $data.collation_name
	
}

function handleObjectCreation([string]$buildFolder,[string]$server,[string]$database) {
	$collation = getCollation $server $database
	Write-Host "Collation :: $collation"
	
	# The purpose of this target is to modify each object (function, procs) to create a dummy changeset first then use ALTER on the following changeset
	# get type for each file
	$rows = Invoke-SqlCmd -ServerInstance $server -Database $database `
		-InputFile "template_files\GetObjectType.sql" `
		-Variable "collation=$collation" `
		-OutputAs DataRows
		
	foreach ($r in $rows) {
		$folder = "$buildFolder\" + $r.folder.Trim()
		$user = $r.username.Trim()
		$filename = "$folder\" + $r.schemaName.Trim() + "." + $r.objectName.Trim() + ".sql"

		write-host "Examining :: $filename"
		
		if (Test-Path $filename) {
			
			
			$f = Get-Item $filename
			$filename = $f.FullName
			$source = Get-Content -Path $filename -Encoding UTF8 -Raw
			$changeset = $f.BaseName.Replace(".", "-").Replace(" ", "-").Replace("_", "-")		
			
			write-host "Processing :: $filename"
			
			$source = Get-Content -Path $filename -Encoding UTF8 -Raw
			$pattern = $r.regex.Trim()
			$replacement = $r.replacement.Trim()
			$changeset = $f.BaseName.Replace(".", "-").Replace(" ", "-").Replace("_", "-")		
			$definition = $r.creationScript;

			# Replace CREATE with ALTER
			# $regex = New-Object System.Text.RegularExpressions.Regex ( `
				# $pattern, `
				# ([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				# -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				# -bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
			# $source = $regex.Replace($source, $replacement);		

			# $regex = New-Object System.Text.RegularExpressions.Regex ( `
				# "--liquibase\sformatted\ssql(.*?)\--changeSet.*?runOnChange:(true|false)", `
				# ([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				# -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				# -bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespacee `
				# -bor [System.Text.RegularExpressions.RegexOptions]::Singleline))
			# $source = $regex.Replace($source, "--liquibase formatted sql`n`n--changeSet " + $user + ":Initial-$changeset-0 endDelimiter:\nGO splitStatements:true stripComments:false runOnChange:false`n$definition`nGO`n`n");		
			
			Set-Content -Path $filename -Value $source -Encoding UTF8
		}
	}
}



#buildPackages "DBApplication|DBApplication:DBApplication" "build" "com.nordax.db" "C:\git\extern\sql-scripts\scripting\DBApplication\DBApplication" 
#init "build" "build\db\DBApplication" "com.nordax.db" "DBApplication" "DBApplication"
#setupRedgateStyle $SrcFolder "build\db\DBApplication" $false
#handleInvalidObjects "build\db\DBApplication"

# if (-not $buildType) {
	# $buildType = "Simple"
# }
# if ($buildType -eq "Simple") {
	# buildPackages ("$database|$database" + ":" + "$database") "build" $GroupId $SrcFolder $SrcDatabaseSuffix
# }
# elseif ($buildType -eq "Package") {
	# buildPackages $ListPackages "build" $GroupId $SrcFolder $SrcDatabaseSuffix
# }

