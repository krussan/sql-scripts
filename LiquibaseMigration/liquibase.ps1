
function build(
	[string]$database,
	[string]$sourcePath,
	[string]$repoPath) {
	
	write-host "---------------------------------------------------------"
	write-host "Database name :: $database"
	write-host "Source folder :: $sourcePath"
	write-host "Repo path :: $repoPath"
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

buildPackages "DBApplication|DBApplication:DBApplication" "repoBase" "com.nordax.db" "C:\git\extern\sql-scripts\scripting\DBApplication\DBApplication" 


  # <target name="build-packages">
    # <foreach item="String" in="${list.packages}" delim=";" property="param.package">
      # <regex input="${param.package}" pattern="(?'packagename'.*?)\|(?'databases'.*)" />
      # <echo message="package :: ${packagename}" />
      # <echo message="databases :: ${databases}" />

      # <property name="modules" value="" />
      # <foreach item="String" in="${databases}" delim="," property="database.module">
        # <regex input="${database.module}" pattern="(?'database'.*?)\:(?'module'.*)" />

        # <property name="modules" value="&lt;module&gt;${module}\db&lt;/module&gt;&#xa;   ${modules}" />
      # </foreach>

      # <echo message="databases :: ${databases}" />
      # <echo message="modules :: ${modules}" />
      
      # <copy file="${directory::get-current-directory()}\template_files\parentpom.xml" tofile="${folder.repo.base}\pom.xml">
        # <filterchain>
          # <replacetokens>
            # <token key="MODULES" value="${modules}" />
            # <token key="PACKAGE" value="${string::to-lower(packagename)}" />
          # </replacetokens>
        # </filterchain>
      # </copy>

      # <foreach item="String" in="${databases}" delim="," property="database.application">
        # <regex input="${database.application}" pattern="(?'database'.*?)\:(?'module'.*)" />

        # <property name="database.name" value="${database}" />
        # <property name="folder.redgate" value="${folder.redgate.base}\${database.name}${redgate.suffix}" />
        # <property name="repo.localpath" value="${folder.repo.base}\${packagename}\Application\${module}\db" />

        # <echo message="&#xa;---------------------------------------------------------&#xa;" />
        # <echo message="Database name :: ${database.name}" />
        # <echo message="Redgate folder :: ${folder.redgate}" />
        # <echo message="Repo path :: ${repo.localpath}" />

        # <call target="build" />
      # </foreach>

    # </foreach>
  # </target>