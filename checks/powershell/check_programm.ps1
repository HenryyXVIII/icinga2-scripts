# Check um zu Prüfen, ob der Prozess "ToControl" in einem bestimmten Userkontext läuft oder nicht

param(
    [string]$user = "",
    [string]$process = "XMLConnector"

)

# Icinga Codes
$ICINGA_OK       = 0
$ICINGA_WARNING  = 1
$ICINGA_CRITICAL = 2
$ICINGA_UNKNOWN  = 3

# exit function belongs to exit codes
function Exit-Check {
    param(
        [int]$Code,
        [string]$Message
    )
    Write-Output "$Message"
    exit $Code
}

$processes = @( Get-Process -IncludeUserName | Where-Object { $_.ProcessName -eq $process })





if ($processes.Count -eq 0) {Exit-Check -Code $ICINGA_CRITICAL -Message "CRITICAL - Programm $process laeuft nicht"}
Write-Output $processes

if ($user) 
{
    $fulluser = ($env:USERDNSDOMAIN.split('.') | Select-Object -First 1 ) + "/" + $user


    if (Get-Process -IncludeUserName | where {$_.Username -eq $user} | ? {$_.Processname -eq $process})
	{ Exit-Check -Code $ICINGA_OK -Message "OK - Programm $process wird ausgefuehrt"}
    else
	{ Exit-Check -Code $ICINGA_CRITICAL -Message "Critical - Programm $process laeuft nicht"}
    
}
elseif ($processes.Count -gt 0) {Exit-Check -Code $ICINGA_OK -Message "OK - Programm $process laeuft unter $($processes | Select-Object -Last 2)" }
