<#
.SYNOPSIS
    Restores GPOs from versioned backups for NIST baseline rollback.

.DESCRIPTION
    Works with the structure created by Script 12A:
        BackupRoot\
          Backup_yyyy-MM-dd_HH-mm-ss\
            GPO backups...
            VersionInfo.txt

    Lets you:
        • List available backup sets
        • Select a specific backup timestamp
        • Restore one or more GPOs from that backup

.PARAMETER BackupRoot
    Root folder where versioned GPO backups are stored.

.PARAMETER BackupTimestamp
    The specific backup folder timestamp (e.g. "2026-04-29_21-00-00").
    If omitted, the latest backup is used.

.PARAMETER GpoNames
    One or more GPO names to restore. If omitted, all GPOs in the backup are restored.

.EXAMPLE
    .\New-NISTGPO-RestoreAndRollback.ps1 `
        -BackupRoot "D:\GPO-Backups" `
        -BackupTimestamp "2026-04-29_21-00-00" `
        -GpoNames "NIST - Firewall Policy"

.EXAMPLE
    .\New-NISTGPO-RestoreAndRollback.ps1 `
        -BackupRoot "D:\GPO-Backups"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO restore & rollback automation
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$BackupRoot,

    [string]$BackupTimestamp,

    [string[]]$GpoNames
)

# -----------------------------
# Resolve Backup Folder
# -----------------------------
if (-not (Test-Path $BackupRoot)) {
    throw "Backup root path not found: $BackupRoot"
}

$backupFolders = Get-ChildItem -Path $BackupRoot -Directory |
                 Where-Object { $_.Name -like "Backup_*" } |
                 Sort-Object Name

if (-not $backupFolders) {
    throw "No backup folders found under $BackupRoot"
}

if ($BackupTimestamp) {
    $targetFolderName = "Backup_$BackupTimestamp"
    $backupFolder = $backupFolders | Where-Object { $_.Name -eq $targetFolderName }

    if (-not $backupFolder) {
        throw "Backup with timestamp '$BackupTimestamp' not found under $BackupRoot"
    }
} else {
    $backupFolder = $backupFolders[-1]   # latest
}

$backupPath = $backupFolder.FullName
Write-Host "Using backup folder: $backupPath" -ForegroundColor Cyan

# -----------------------------
# Discover GPO Backups
# -----------------------------
$gpoBackupInfo = Get-GPOBackup -Path $backupPath -ErrorAction SilentlyContinue

if (-not $gpoBackupInfo) {
    throw "No GPO backups found in $backupPath"
}

if (-not $GpoNames) {
    $GpoNames = $gpoBackupInfo.DisplayName
    Write-Host "No GPO names specified; restoring all GPOs in this backup set." -ForegroundColor Yellow
}

# -----------------------------
# Restore Selected GPOs
# -----------------------------
foreach ($gpoName in $GpoNames) {

    $backup = $gpoBackupInfo | Where-Object { $_.DisplayName -eq $gpoName }

    if (-not $backup) {
        Write-Host "No backup found for GPO '$gpoName' in $backupPath" -ForegroundColor Red
        continue
    }

    Write-Host "Restoring GPO: $gpoName (ID: $($backup.ID))" -ForegroundColor Yellow

    try {
        Restore-GPO -Guid $backup.ID -Path $backupPath -Confirm:$false -ErrorAction Stop
        Write-Host "Successfully restored GPO '$gpoName'" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to restore GPO '$gpoName': $_" -ForegroundColor Red
    }
}

Write-Host "`nGPO restore/rollback operation complete." -ForegroundColor Green
