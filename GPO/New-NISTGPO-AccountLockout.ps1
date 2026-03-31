<#
.SYNOPSIS
    Creates or updates a GPO to configure Account Lockout Policy settings
    aligned with NIST AC-7 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    Account Lockout Policy settings under:

        Computer Configuration →
        Policies →
        Windows Settings →
        Security Settings →
        Account Policies →
        Account Lockout Policy

    All values are variable-driven for easy modification and reuse.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER LockoutThreshold
    Number of failed logon attempts before the account is locked.

.PARAMETER LockoutDuration
    Duration (in minutes) the account remains locked.

.PARAMETER ResetCounter
    Time (in minutes) before the failed logon counter resets.

.EXAMPLE
    .\New-NISTGPO-AccountLockout.ps1 `
        -GpoName "NIST - Account Lockout Policy" `
        -TargetOU "OU=Workstations,DC=example,DC=com"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO automation
    Category: Account Lockout Policy
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [int]$LockoutThreshold = 5,   # NIST-aligned default
    [int]$LockoutDuration  = 15,  # minutes
    [int]$ResetCounter     = 15   # minutes
)

# -----------------------------
# Create or retrieve the GPO
# -----------------------------
Write-Host "Creating or retrieving GPO: $GpoName" -ForegroundColor Cyan
$gpo = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue

if (-not $gpo) {
    $gpo = New-GPO -Name $GpoName
    Write-Host "Created new GPO: $GpoName"
} else {
    Write-Host "Using existing GPO: $GpoName"
}

# -----------------------------
# Link GPO to the target OU
# -----------------------------
Write-Host "Linking GPO to: $TargetOU" -ForegroundColor Cyan
New-GPLink -Name $GpoName -Target $TargetOU -Enforced $false -ErrorAction SilentlyContinue

# -----------------------------
# Configure Account Lockout Policy
# -----------------------------
Write-Host "Configuring Account Lockout Policy..." -ForegroundColor Cyan

# These settings are applied via secedit-based GPO registry keys

# Account Lockout Threshold
Set-GPRegistryValue -Name $GpoName `
    -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "LockoutThreshold" `
    -Type DWord `
    -Value $LockoutThreshold

# Lockout Duration
Set-GPRegistryValue -Name $GpoName `
    -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "LockoutDuration" `
    -Type DWord `
    -Value $LockoutDuration

# Reset Counter
Set-GPRegistryValue -Name $GpoName `
    -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "ResetLockoutCount" `
    -Type DWord `
    -Value $ResetCounter

Write-Host "Account Lockout Policy configuration complete." -ForegroundColor Green