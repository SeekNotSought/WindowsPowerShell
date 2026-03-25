<#
.SYNOPSIS
    Audits and manages local Windows user accounts and profile folders.

.DESCRIPTION
    This script performs a full lifecycle audit of local users and their
    corresponding profile folders. It identifies stale profiles, orphaned
    profiles, disabled accounts, and optionally archives and removes profiles.

.PARAMETER DaysInactive
    Number of days since last logon to consider a profile stale.

.PARAMETER Remediate
    Enables remediation actions such as archiving and deleting stale profiles.

.PARAMETER ArchivePath
    Directory where stale profiles will be zipped before deletion.

.NOTES
    Author: SeekNotSought
    Version: 1.0.0
    Last Updated: 2026-03-25

.TODO
    - Add CSV/JSON export
    - Add remote computer support
    - Add Event Log integration
#>

[CmdletBinding()]
param(
    [int]$DaysInactive = 60,
    [switch]$Remediate,
    [string]$ArchivePath = "C:\ProfileArchives"
)

function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Output "$timestamp`t$Message"
}

function Get-LocalUserInfo {
    Write-Log "Collecting local user information..."
    return Get-LocalUser | Select-Object Name, Enabled, LastLogon
}

function Get-ProfileFolders {
    Write-Log "Enumerating profile folders..."
    $exclude = @("Public","Default","Default User","All Users","WDAGUtilityAccount")

    return Get-ChildItem "C:\Users" -Directory |
        Where-Object { $_.Name -notin $exclude } |
        Select-Object Name, FullName
}

function Get-ProfileLastWrite {
    param([string]$ProfilePath)

    $ntuser = Join-Path $ProfilePath "NTUSER.DAT"
    if (-not (Test-Path $ntuser)) { return $null }

    try {
        $item = Get-Item $ntuser -ErrorAction Stop
        return $item.LastWriteTime
    }
    catch {
        return $null
    }
}

function Build-ProfileReport {
    Write-Log "Building profile lifecycle report..."

    $users = Get-LocalUserInfo
    $profiles = Get-ProfileFolders

    $report = foreach ($p in $profiles) {
        $userMatch = $users | Where-Object { $_.Name -eq $p.Name }

        $lastWrite = Get-ProfileLastWrite -ProfilePath $p.FullName
        $daysSinceWrite = if ($lastWrite) { (New-TimeSpan -Start $lastWrite -End (Get-Date)).Days } else { $null }

        [PSCustomObject]@{
            UserName        = $p.Name
            ProfilePath     = $p.FullName
            ExistsAsUser    = [bool]$userMatch
            Enabled         = $userMatch.Enabled
            LastLogon       = $userMatch.LastLogon
            LastWrite       = $lastWrite
            DaysInactive    = $daysSinceWrite
            IsStale         = if ($daysSinceWrite -ge $DaysInactive) { $true } else { $false }
            IsOrphaned      = if (-not $userMatch) { $true } else { $false }
        }
    }

    return $report
}

function Archive-And-RemoveProfile {
    param([PSCustomObject]$Profile)

    if (-not (Test-Path $ArchivePath)) {
        New-Item -ItemType Directory -Path $ArchivePath | Out-Null
    }

    $zipName = "$($Profile.UserName)_$(Get-Date -Format yyyyMMddHHmmss).zip"
    $zipPath = Join-Path $ArchivePath $zipName

    Write-Log "Archiving profile: $($Profile.ProfilePath) → $zipPath"
    Compress-Archive -Path $Profile.ProfilePath -DestinationPath $zipPath -ErrorAction SilentlyContinue

    Write-Log "Removing profile folder: $($Profile.ProfilePath)"
    Remove-Item -Path $Profile.ProfilePath -Recurse -Force -ErrorAction SilentlyContinue
}

function Show-ProfileReport {
    param([array]$Report)

    Write-Host "`n===== Windows User & Profile Lifecycle Report =====" -ForegroundColor Cyan

    foreach ($entry in $Report) {
        Write-Host "`nUser/Profile: $($entry.UserName)" -ForegroundColor Yellow
        Write-Host "Profile Path:     $($entry.ProfilePath)"
        Write-Host "Exists as User:   $($entry.ExistsAsUser)"
        Write-Host "Enabled:          $($entry.Enabled)"
        Write-Host "Last Logon:       $($entry.LastLogon)"
        Write-Host "LastWrite (NTUSER): $($entry.LastWrite)"
        Write-Host "Days Inactive:    $($entry.DaysInactive)"
        Write-Host "Stale Profile:    $($entry.IsStale)"
        Write-Host "Orphaned Profile: $($entry.IsOrphaned)"
    }

    Write-Host "`n=====================================================`n"
}

# MAIN EXECUTION
$report = Build-ProfileReport
Show-ProfileReport -Report $report

if ($Remediate) {
    Write-Log "Remediation enabled. Processing stale/orphaned profiles..."

    $targets = $report | Where-Object { $_.IsStale -or $_.IsOrphaned }

    foreach ($profile in $targets) {
        Archive-And-RemoveProfile -Profile $profile
    }

    Write-Log "Rebuilding report after remediation..."
    $report = Build-ProfileReport
    Show-ProfileReport -Report $report
}