<#
.SYNOPSIS
    Creates or updates a GPO to configure classic Audit Policy settings
    aligned with NIST AU-2, AU-6, and AU-12 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    the legacy Audit Policy categories located under:

        Computer Configuration →
        Policies →
        Windows Settings →
        Security Settings →
        Local Policies →
        Audit Policy

    These settings are applied using secedit-compatible registry values.
    All values are variable-driven for easy modification and reuse.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER AuditSettings
    A hashtable defining each audit category and its desired setting:
    0 = No auditing
    1 = Success
    2 = Failure
    3 = Success and Failure

.EXAMPLE
    .\New-NISTGPO-AuditPolicy.ps1 `
        -GpoName "NIST - Audit Policy (Legacy)" `
        -TargetOU "OU=Servers,DC=example,DC=com"

.NOTES
    Author: SeekNotSought=
    Purpose: NIST-aligned GPO automation
    Category: Audit Policy (Legacy)
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$AuditSettings = @{
        "AuditAccountLogon"        = 3
        "AuditAccountManagement"   = 3
        "AuditDirectoryService"    = 3
        "AuditLogonEvents"         = 3
        "AuditObjectAccess"        = 3
        "AuditPolicyChange"        = 3
        "AuditPrivilegeUse"        = 3
        "AuditProcessTracking"     = 1
        "AuditSystemEvents"        = 3
    }
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
# Configure Audit Policy (Legacy)
# -----------------------------
Write-Host "Configuring classic Audit Policy settings..." -ForegroundColor Cyan

$baseKey = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit"

foreach ($setting in $AuditSettings.GetEnumerator()) {

    $name  = $setting.Key
    $value = [int]$setting.Value

    Write-Host "Setting $name = $value" -ForegroundColor Yellow

    Set-GPRegistryValue -Name $GpoName `
        -Key $baseKey `
        -ValueName $name `
        -Type DWord `
        -Value $value
}

Write-Host "Audit Policy (Legacy) configuration complete." -ForegroundColor Green