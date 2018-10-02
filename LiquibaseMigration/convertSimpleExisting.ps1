param([Parameter(Mandatory=$true)][string]$SrcFolder,
	[Parameter(Mandatory=$true)][string]$Server,
	[Parameter(Mandatory=$true)][string]$Database,
	[Parameter(Mandatory=$true)][string]$GroupId,
	[string]$DbUser,
	[string]$DbPass)

#############################################################################
#If Powershell is running the 32-bit version on a 64-bit machine, we 
#need to force powershell to run in 64-bit mode .
#############################################################################
if ($env:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    write-warning "Y'arg Matey, we're off to never never land..... (64-bit)"
    if ($myInvocation.Line) {
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile $myInvocation.Line
    }else{
        &"$env:WINDIR\sysnative\windowspowershell\v1.0\powershell.exe" -NonInteractive -NoProfile -file "$($myInvocation.InvocationName)" $args
    }
exit $lastexitcode
}

	
. ".\liquibase.ps1"

buildPackages ("$database`|$database`:$database") "build" $GroupId $SrcFolder ""
	