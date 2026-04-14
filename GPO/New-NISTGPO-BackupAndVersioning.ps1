<#
.SYNOPSIS
    Backs up GPOs and maintains versioned history for NIST baseline policies.

.DESCRIPTION
    This script automates GPO backup and versioning. It:
        • Creates timestamped backup directories
        • Backs up one or more GPOs
        • Writes version metadata (timestamp, user, notes)
        • Maintains a clean, professional version history

    This script is designed to support the NIST baseline GPOs created in Scripts 1–10.

.PARAMETER GpoNames
    One or more GPO names to back up.

.PARAMETER BackupRoot
    Root folder where versioned GPO backups will be stored.

.PARAMETER Notes
    Optional change notes (e.g., “Updated audit policy”, “Added AppLocker rules”).

.EXAMPLE
    .\New-NISTGPO-BackupAndVersioning.ps1 `
        -GpoNames "NIST - Account Lockout Policy","NIST - Firewall Policy" `
        -BackupRoot "D:\GPO-Backups" `
        -Notes "Quarterly baseline update"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO backup & versioning automation
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string[]]$GpoNames,

    [Parameter(Mandatory)]
    [string]$BackupRoot,

    [string]$Notes = "No notes provided."
)

# -----------------------------
# Prepare Backup Directory
# -----------------------------
$timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
$backupPath = Join-Path $BackupRoot "Backup_$timestamp"

Write-Host "Creating backup directory: $backupPath" -ForegroundColor Cyan
New-Item -Path $backupPath -ItemType Directory -Force | Out-Null

# -----------------------------
# Backup Each GPO
# -----------------------------
foreach ($gpoName in $GpoNames) {

    Write-Host "Backing up GPO: $gpoName" -ForegroundColor Yellow

    try {
        Backup-GPO -Name $gpoName -Path $backupPath -ErrorAction Stop

        Write-Host "Successfully backed up $gpoName" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to back up $gpoName: $_" -ForegroundColor Red
    }
}

# -----------------------------
# Write Version Metadata
# -----------------------------
$metadata = [PSCustomObject]@{
    Timestamp   = $timestamp
    User        = $env:USERNAME
    GPOs        = ($GpoNames -join ", ")
    Notes       = $Notes
}

$metadataPath = Join-Path $backupPath "VersionInfo.txt"

Write-Host "Writing version metadata to $metadataPath" -ForegroundColor Cyan
$metadata | Out-File -FilePath $metadataPath -Encoding UTF8

# -----------------------------
# Completion
# -----------------------------
Write-Host "`nGPO backup and versioning complete." -ForegroundColor Green
Write-Host "Backup stored at: $backupPath"