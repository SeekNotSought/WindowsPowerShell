<#
.SYNOPSIS
    Checks Windows Update compliance and performs remediation if needed.

.DESCRIPTION
    This script evaluates Windows Update status, identifies failures or pending
    updates, attempts automated remediation, and outputs a compliance report.

.NOTES
    Author: SeekNotSought
    Version: 1.0.0
    Last Updated: 2026-03-23

.TODO
    - Add optional export to CSV/JSON
    - Add parameter for remote computer targeting
    - Add logging to Windows Event Log
#>

[CmdletBinding()]
param(
    [switch]$Remediate,
    [switch]$VerboseOutput
)

function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Output "$timestamp`t$Message"
}

function Get-WindowsUpdateStatus {
    Write-Log "Checking Windows Update status..."

    $result = @{
        WindowsUpdateService = $null
        PendingReboot        = $false
        LastScanTime         = $null
        LastInstallTime      = $null
        FailedUpdates        = @()
    }

    # Check service
    $service = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    $result.WindowsUpdateService = $service.Status

    # Pending reboot
    $pendingRebootPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    )

    foreach ($path in $pendingRebootPaths) {
        if (Test-Path $path) {
            $result.PendingReboot = $true
        }
    }

    # Update history
    $history = Get-WinEvent -LogName "Microsoft-Windows-WindowsUpdateClient/Operational" -ErrorAction SilentlyContinue |
               Where-Object { $_.Id -in 19,20,31 } |
               Select-Object -First 50

    $result.LastScanTime = ($history | Where-Object Id -eq 31 | Select-Object -First 1).TimeCreated
    $result.LastInstallTime = ($history | Where-Object Id -eq 19 | Select-Object -First 1).TimeCreated

    # Failed updates
    $result.FailedUpdates = $history |
        Where-Object Id -eq 20 |
        Select-Object TimeCreated, Message

    return $result
}

function Repair-WindowsUpdate {
    Write-Log "Starting Windows Update remediation..."

    Write-Log "Stopping update services..."
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service bits -Force -ErrorAction SilentlyContinue

    Write-Log "Resetting update cache..."
    Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Log "Restarting services..."
    Start-Service wuauserv
    Start-Service bits

    Write-Log "Forcing update scan..."
    UsoClient.exe StartScan | Out-Null

    Write-Log "Attempting update install..."
    UsoClient.exe StartInstall | Out-Null

    Write-Log "Remediation complete."
}

function Show-ComplianceReport {
    param([hashtable]$Status)

    Write-Host "`n===== Windows Update Compliance Report =====" -ForegroundColor Cyan
    Write-Host "Windows Update Service: $($Status.WindowsUpdateService)"
    Write-Host "Pending Reboot:        $($Status.PendingReboot)"
    Write-Host "Last Scan Time:        $($Status.LastScanTime)"
    Write-Host "Last Install Time:     $($Status.LastInstallTime)"
    Write-Host "`nFailed Updates:" -ForegroundColor Yellow

    if ($Status.FailedUpdates.Count -eq 0) {
        Write-Host "  None"
    } else {
        $Status.FailedUpdates | Format-Table TimeCreated, Message -AutoSize
    }

    Write-Host "============================================`n"
}

# MAIN EXECUTION
$status = Get-WindowsUpdateStatus
Show-ComplianceReport -Status $status

if ($Remediate) {
    Write-Log "Remediation flag detected. Beginning repair..."
    Repair-WindowsUpdate
    Write-Log "Re-checking update status..."
    $status = Get-WindowsUpdateStatus
    Show-ComplianceReport -Status $status
}