[CmdletBinding()]


param(
    [string]$Server = "localhost",
    [int]$Warn = 13,
    [int]$Crit = 17,
    [switch]$IncludeAdmin = $False
)

# --- Icinga/Nagios Exit Codes ---
$ICINGA_OK       = 0
$ICINGA_WARNING  = 1
$ICINGA_CRITICAL = 2
$ICINGA_UNKNOWN  = 3

function Exit-Check {
    param(
        [int]$Code,
        [string]$Message
    )
    Write-Output "$Message, total: $($users.count) |logged_in_user=$($users.count);$Warn;$Crit;0"
    exit $Code
}

$users = @(quser /server:$Server | Select-Object -Skip 1)

if ($IncludeAdmin -eq $false) {
    $users = $users | Where-Object { $_ -notmatch 'administrator' }
}

#foreach ($user in $users) { Write-Output "$user" }
#Write-Output "$($users.count)"
$count = $users.Count
if ( $count -eq 0) { Exit-Check -Code $ICINGA_OK -Message "OK - no loggins IDLE "}
elseif ( $count -lt $Warn) { Exit-Check -Code $ICINGA_OK -Message "OK - some users logged in" }
elseif ( $count -lt $Crit) { Exit-Check -Code $ICINGA_WARNING -Message "WARNING - a lot of users logged in" }
elseif ( $count -ge $Crit) { Exit-Check -Code $ICINGA_CRITICAL -Message "CRITICAL - to many users logged in" }
else { Exit-Check -Code $ICINGA_UNKNOWN -Message "UNKNOWN - strange value" }



#minimal = if ($($users.count) -gt 1) { Write-Output "to many users"; Exit 1 }

#$users = @(quser| Select-Object -Skip 1); if ($($users.count) -gt 1) { Write-Output "to many users"; Exit 1 }

#$users = @(quser| Select-Object -Skip 1).count ; if ($users -gt 1) { Write-Output "to many users: $users"; Exit 1 }

#icinga normal = $$users = @(quser| Select-Object -Skip 1).count ; if ($$users -gt 1) { Write-Output "to many users: $$users"; Exit 1 }

#icinga ohne admin = $$users = @(quser| Select-Object -Skip 1 | Where-Object { $$_ -notmatch 'administrator' }).count ; if ($$users -gt 1) { Write-Output "to many users: $$users"; Exit 1 }