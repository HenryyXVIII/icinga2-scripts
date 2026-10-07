[CmdletBinding()]

<#
.SYNOPSIS
    Checks the number of logged-in users for Icinga.

.DESCRIPTION
    Uses quser to determine the number of logged-in users.
    Returns OK, WARNING or CRITICAL depending on the configured thresholds.

.PARAMETER Warn
    Number of logged-in users at which WARNING is returned.

.PARAMETER Crit
    Number of logged-in users at which CRITICAL is returned.

.PARAMETER OutputUser
    Outputs the names of the logged-in users.

.PARAMETER InlcudeAdmin
    Includes administrator to the users counted

.EXAMPLE
    .\check_users.ps1 -Warn 3 -Crit 5
    warn =< 3 user s
    critical =< 5 users

.EXAMPLE
    .\check_users.ps1 -Warn 3 -Crit 5 -OutputUser -IncludeAdmin

.NOTES
    Exit codes:
    0 = OK
    1 = WARNING
    2 = CRITICAL
    3 = UNKNOWN
#>

param(
    [string]$Server = "localhost",
    [int]$Warn = 13,
    [int]$Crit = 17,
    [switch]$IncludeAdmin = $False,
    [switch]$OutputUser = $False
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


    if ($OutputUser -eq $true) {
        $userNames = foreach ($user in $users) {
            (($user.Trim() -replace '^>', '') -split '\s+')[0]
        }

        $loggedin = ",U: " + ($userNames -join ", ")
    }


    Write-Output "$Message, total: $($users.count) $loggedin|logged_in_user=$($users.count);$Warn;$Crit;0"
    exit $Code
}

#$users = @(quser /server:$Server | Select-Object -Skip 1)
$users = @(quser | Select-Object -Skip 1)

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