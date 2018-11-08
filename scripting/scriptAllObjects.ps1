param(
	[string]$server,
	[string]$database,
	[string]$outputpath,
	[string[]]$excludeRegex
)

$FolderMap = @{
	"Deploy" = "Deploy"
	"Assemblies" = "Assemblies"
	"Data" = "Data"
	"Triggers" = "Database Triggers"
	"Defaults" = "Defaults"
	"ExtendedProperties" = "Extended Properties"
	"UserDefinedFunctions" = "Functions"
	"Rules" = "Rules"
	"Search property Lists" = "Search property Lists"
	"Asymmetric Keys" = "Security\Asymmetric Keys"
	"Certificates" = "Security\Certificates"
	"Roles" = "Security\Roles"
	"Schemas" = "Security\Schemas"
	"Symmetric Keys" = "Security\Symmetric Keys"
	"Sequences" = "Sequences"
	"Contracts" = "Service Broker\Contracts"
	"Event Notifications" = "Service Broker\Event Notifications"
	"Message Types" = "Service Broker\Message Types"
	"Queues" = "Service Broker\Queues"
	"Remote Service Bindings" = "Service Broker\Remote Service Bindings"
	"Routes" = "Service Broker\Routes"
	"Services" = "Service Broker\Services"
	"Full Text Catalogs" = "Storage\Full Text Catalogs"
	"Full Text Stoplists" = "Storage\Full Text Stoplists"
	"PartitionFunctions" = "Storage\Partition Functions"
	"PartitionSchemes" = "Storage\Partition Schemes"
	"FileGroups" = "Storage\File Groups"
	"StoredProcedures" = "Stored Procedures"
	"Synonyms" = "Synonyms"
	"Tables" = "Tables"
	"View triggers" = "View triggers"
	"UserDefinedDataTypes" = "Types\User-defined Data Types"
	"UserDefinedTableTypes" = "Types\User-defined Data Types"
	"XmlSchemaCollections" = "Types\XML Schema Collections"
	"Views" = "Views"
}

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $server
 
$IncludeTypes = @("Assemblies", "Triggers", "Defaults", "ExtendedProperties", "Rules", "Roles", "Tables", "Schemas", "StoredProcedures"
	,"Sequences", "Views", "UserDefinedFunctions", "Synonyms", "UserDefinedDataTypes", "UserDefinedDataTypes", "UserDefinedTableTypes", "Triggers", "PartitionSchemes", "PartitionFunctions"
	,"XmlSchemaCollections")
$ExcludeSchemas = @("sys", "Information_Schema")
 
 
$so = new-object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions')
#$so.IncludeIfNotExists = 0
#$so.SchemaQualify = 1
#$so.AllowSystemObjects = 0
#$so.ScriptDrops = 0 #Script Drop Objects
$so.ScriptSchema = $true;
$so.ScriptData = $false;
$so.NoCommandTerminator = $false;
$so.Indexes = $true;
$so.ClusteredIndexes = $true;
$so.DriAllKeys = $true;
$so.ExtendedProperties = $true;
$so.IncludeIfNotExists = $false;
$so.NoCollation = $true;
$so.Permissions = $false;
$so.ScriptDataCompression = $true;
$so.Triggers = $true;
$so.XmlIndexes = $true;
$so.AllowSystemObjects = $false;
$so.AnsiFile = $false;
$so.AnsiPadding = $false;
$so.ScriptBatchTerminator = $true;
$so.Encoding = [System.Text.Encoding]::UTF8  


$db = $srv.Databases[$database]

$dbname = "$database".replace("[", "").replace("]", "")
$dbpath = "$outputpath" + "\" + "$dbname"

write-host "Checking path :: $dbpath";

if (!(Test-Path $dbpath)) { 
	new-item -type directory -name "$dbname" -path "$outputpath" | out-null
}

foreach ($Type in $IncludeTypes)
{
	write-host "Processing type :: $Type"
	$typeFolder = $FolderMap[$Type];
	if (!$typeFolder) {
		$typeFolder = $Type
	}
	
	$objpath = "$dbpath\$typeFolder"
	
	if (!(Test-Path $objpath)) { 
		new-item -type directory -name "$typeFolder" -path "$dbpath" | out-null
	}
	
	write-host $database + " " + $db
	foreach ($objs in $db.$Type)
	{
		Write-host "Checking object :: $objs"
		If ($ExcludeSchemas -notcontains $objs.Schema)
		{
			$ObjName = "$objs".replace("[", "").replace("]", "")
			
			$ismatch = $false;
			foreach ($pattern in $excludeRegex) {
				$regex = New-Object System.Text.RegularExpressions.Regex ( `
				$pattern, `
				([System.Text.RegularExpressions.RegexOptions]::MultiLine `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase `
				-bor [System.Text.RegularExpressions.RegexOptions]::IgnorePatternWhitespace))
				
				if ($regex.IsMatch($ObjName)) {
					$ismatch = $true
					break;
				}
			
			}
			
			if (-not $ismatch) {
				$OutFile = "$objpath\$ObjName.sql"
				write-host "Processing :: $OutFile"
			
				$objs.Script($so) | Out-File $OutFile -Encoding UTF8
			}
			else {
				write-host "Skipping :: $ObjName"
			}
		}
	}
}
