<#
.SYNOPSIS
    Enumerates all SIDs on the system and resolves them to usernames.

.DESCRIPTION
    This script automatically discovers Security Identifiers (SIDs) from multiple
    authoritative sources on a Windows 11 system, including:
        - Local user accounts
        - Local groups
        - Registry ProfileList (user profiles)
        - Well-known built-in accounts
        - Service SIDs (if present)

    Each SID is then translated into an NTAccount (DOMAIN\User or COMPUTER\User).
    Unresolvable SIDs (e.g., deleted accounts) are returned with a status message.

.EXAMPLE
    .\Resolve-AllSIDs.ps1
    Enumerates all SIDs on the device and resolves them to usernames.

.NOTES
    Author: SeekNotSought
    Version: 1.0
    Created: 2026-02-21
    Last Updated: 2026-02-21

    TODO:
        - Add CSV/JSON export switches
        - Add pipeline support
        - Add module wrapper
        - Add ACL enumeration (filesystem, registry)
#>

function Resolve-SID {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SID
    )

    try {
        $sidObj = New-Object System.Security.Principal.SecurityIdentifier($SID)
        $account = $sidObj.Translate([System.Security.Principal.NTAccount])

        return [PSCustomObject]@{
            SID      = $SID
            Username = $account.Value
            Source   = $null
            Status   = "Resolved"
        }
    }
    catch {
        return [PSCustomObject]@{
            SID      = $SID
            Username = $null
            Source   = $null
            Status   = "Unresolvable"
        }
    }
}

Write-Host "Enumerating SIDs..." -ForegroundColor Cyan

# --- Collect SIDs from multiple sources ---

$sidList = @()

# 1. Local users
$sidList += Get-LocalUser | Select-Object -ExpandProperty SID

# 2. Local groups
$sidList += Get-LocalGroup | Select-Object -ExpandProperty SID

# 3. ProfileList (registry)
$sidList += Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" |
            Select-Object -ExpandProperty PSChildName

# 4. Well-known SIDs (SYSTEM, LOCAL SERVICE, NETWORK SERVICE)
$wellKnown = @(
    "S-1-5-18",
    "S-1-5-19",
    "S-1-5-20"
)
$sidList += $wellKnown

# Remove duplicates
$sidList = $sidList | Sort-Object -Unique

Write-Host "Found $($sidList.Count) unique SIDs." -ForegroundColor Green

# --- Resolve each SID ---
$results = foreach ($sid in $sidList) {
    $result = Resolve-SID -SID $sid
    $result.Source = "Local System"
    $result
}

# Output results
$results | Format-Table -AutoSize