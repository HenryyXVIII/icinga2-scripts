# Author Henry
# Version 1.2
# check if process is running
<#
.SYNOPSIS
    Checks whether a specified process is running.

.DESCRIPTION
    Checks whether a process is running on the system and optionally
    verifies that it is running under a specified user account.

    The script returns Icinga-compatible exit codes:
      0 = OK       - Process is running as expected
      1 = WARNING  - Process is running under a different user
      2 = CRITICAL - Process is not running
      3 = UNKNOWN  - No process name specified

.PARAMETER user
    Optional username under which the process is expected to run.
    The username is combined with the Windows domain.

.PARAMETER process
    Name of the process to check, without the .exe extension.

.PARAMETER Help
    Displays detailed help information about the script.

.EXAMPLE
    .\Check-Process.ps1 -process "notepad"

    Checks whether the notepad process is running.

.EXAMPLE
    .\Check-Process.ps1 -process "notepad" -user "henry"

    Checks whether notepad is running under the specified user.
    Script currently just using domain name not lokal pc name, so it can endup in warning couse username wrongly build

.EXAMPLE
    .\Check-Process.ps1 -Help

    Displays detailed help information.

.EXAMPLE
    Get-Help .\Check-Process.ps1 -Detailed

    Displays the detailed PowerShell help documentation.

.NOTES
    Author: Henry
    Date: 14.10.2026
    Purpose: Icinga process monitoring
#>

#####################

param(
    [string]$user = "",
    [string]$process = "",
    [switch]$Help,
    [switch]$srestart = $false,
    [string]$ppath
)

# Display help if requested
if ($Help) {
    Get-Help $PSCommandPath -Detailed
    exit 0
}

#######################

# Icinga Codes + EXIT FUNCTION
$ICINGA_OK       = 0
$ICINGA_WARNING  = 1
$ICINGA_CRITICAL = 2
$ICINGA_UNKNOWN  = 3

function Exit-Check {
    param(
        [int]$Code,
        [string]$Message
    )
    #if ( ($code -eq 2) -and ( $srestart -eq "true")) {Try-Start -service $process}
    
    Write-Output "$Message"
    exit $Code
}

########################

# RESTART
function  Try-Start 
{
    param( [string]$service)
    $i = 0
    # srestart is true than skip => instant crit
    if ($srestart -eq $false) {Exit-Check -Code $ICINGA_CRITICAL -Message "CRITICAL - Programm $process laeuft nicht!"}
    do {
        
        #start and tell

        Start-Process -FilePath $ppath
        $i++
        Write-Output "trying start $service attemp $i"
        
        if (Get-Process -Name $process -ErrorAction SilentlyContinue) {Exit-Check -Code $ICINGA_WARNING -Message "WARNING - Programm lief nicht, konnte aber gestartet werden"}

        #to many starts => Critical
        if ($i -gt 5) { Exit-Check -Code $ICINGA_CRITICAL -Message "CRITICAL - Programm $process laeuft nicht und konnte nicht gestartet werden!" }

    } while ($true)

    

}

#BUILDUSER
function Build-User {

    if (!$env:USERDOMAIN) {
        # USERDOMAIN EMPTY
        Write-Output "noenv"
        $builduser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    }
    elseif  (!$env:USERDNSDOMAIN) {
        # USERDNSDOMAIN EMPTY
        $builduser = ($env:USERDOMAIN.split('.') | Select-Object -First 1 ) + "\" + $user
    }
    else {
        # build full user name with Domain + user
        $builduser = ($env:USERDNSDOMAIN.split('.') | Select-Object -First 1 ) + "\" + $user
    }
    return $builduser


}


# UKNOWN 0 NO PROCESS
if (!$process) { Exit-Check -Code $ICINGA_UNKNOWN -Message "UNKNOWN - no process specified" }


# LIST PROCESS
$processes = @( Get-Process -IncludeUserName | Where-Object { $_.ProcessName -eq $process })





# if process not found Crit
if ($processes.Count -eq 0) {Try-Start -service $process}

# If process not running exit with CRITICAL

$runninguser = (Get-Process -IncludeUserName -Name $process).UserName

if ($user) 
{
    $fulluser = Build-User 



    # If Running and under given user exit with OK
    if (Get-Process -IncludeUserName | where {$_.Username -eq $fulluser} | ? {$_.Processname -eq $process})
    { 
        Exit-Check -Code $ICINGA_OK -Message "OK - Programm $process wird ausgefuehrt von: $($fulluser.Replace('\', '/'))"}

    # exit WARNING if running but not under given user
    elseif ($processes.Count -gt 0) 
    
    { Exit-Check -Code $ICINGA_WARNING -Message "WARNING - Programm laeuft, aber nicht unter $($fulluser.Replace('\', '/')) sondern unter $($runninguser.Replace('\', '/') | Select-Object -First 1)"}

    # this is kind auseless, couse it would already exit in first if statement
    else { Exit-Check -Code $ICINGA_CRITICAL -Message "Critical - Programm $process laeuft nicht usm"}
    
    
}
# if Process running and no user specified than exit with OK
elseif ($processes.Count -gt 0) {Exit-Check -Code $ICINGA_OK -Message "OK - Programm $process laeuft unter dem User: $($runninguser.Replace('\', '/')| Select-Object -First 1)" }
    
