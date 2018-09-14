param(
	[string]$server,
	[string]$database,
	[string]$outputpath
)

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null
$srv = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $server
 
$IncludeTypes = @("Tables", "StoredProcedures", "Views", "UserDefinedFunctions", "Synonyms", "UserDefinedDataTypes", "UserDefinedTableTypes", "Triggers", "PartitionSchemes", "PartitionFunctions")
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
$so.IncludeIfNotExists = $true;
$so.NoCollation = $true;
$so.Permissions = $false;
$so.ScriptDataCompression = $true;
$so.Triggers = $true;
$so.XmlIndexes = $true;
$so.AllowSystemObjects = $false;
$so.AnsiFile = $false;
$so.AnsiPadding = $false;
$so.ScriptBatchTerminator = $true;


$db = $srv.Databases[$database]

$dbname = "$db".replace("[", "").replace("]", "")
$dbpath = "$outputpath" + "\" + "$dbname" + "\"
if (!(Test-Path $dbpath))
{ $null = new-item -type directory -name "$dbname" -path "$outputpath" }

foreach ($Type in $IncludeTypes)
{
	$objpath = "$dbpath" + "$Type" + "\"
	if (!(Test-Path $objpath))
	{ $null = new-item -type directory -name "$Type" -path "$dbpath" }
	foreach ($objs in $db.$Type)
	{
		If ($ExcludeSchemas -notcontains $objs.Schema)
		{
			$ObjName = "$objs".replace("[", "").replace("]", "")
			$OutFile = "$objpath" + "$ObjName" + ".sql"
			$objs.Script($so) + "GO" | out-File $OutFile #-Append
		}
	}
}
