[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
$serverInstance = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $ServerName
 
$IncludeTypes = @("tables", "StoredProcedures", "Views", "UserDefinedFunctions")
$ExcludeSchemas = @("sys", "Information_Schema")
 
 
$so = new-object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions')
$so.IncludeIfNotExists = 0
$so.SchemaQualify = 1
$so.AllowSystemObjects = 0
$so.ScriptDrops = 0 #Script Drop Objects
 
$dbs = $serverInstance.Databases
foreach ($db in $dbs)
{
    $dbname = "$db".replace("[", "").replace("]", "")
    $dbpath = "$path" + "$dbname" + "\"
    if (!(Test-Path $dbpath))
    { $null = new-item -type directory -name "$dbname" -path "$path" }
    
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
}