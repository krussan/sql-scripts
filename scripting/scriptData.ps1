param(
	[string]$server,
	[string]$database,
	[string]$user,
	[string]$pass,
	[string]$outputpath,
	[string[]]$tables,
	[boolean]$generateLiquibaseHeader
)

$liqHeader = 0;
if ($generateLiquibaseHeader) {
	$liqHeader = 1;
}

foreach ($table in $tables)
{
	if (!$user) {
		Write-Host "sqlcmd -i scriptData.sql -S $server -v DataTable=$table -v GenerateLiquibaseHeader=$liqHeader -v UserName=$env:UserName -o data_$table.sql -d $database -y0"
		& sqlcmd -i scriptData.sql -S $server -v DataTable=$table -v GenerateLiquibaseHeader=$liqHeader -v UserName=$env:UserName -o "$outputpath\data_$table.sql" -d $database -y0
	}
	else {
		Write-Host "sqlcmd -i scriptData.sql -S $server -U $user -P $pass -v DataTable=$table -v GenerateLiquibaseHeader=$liqHeader -v UserName=$user -o data_$table.sql -d $database -y0"
		& sqlcmd -i scriptData.sql -S $server -U $user -P $pass -v DataTable=$table -v GenerateLiquibaseHeader=$liqHeader -v UserName=$user -o "$outputpath\data_$table.sql" -d $database -y0
	}
	
}
