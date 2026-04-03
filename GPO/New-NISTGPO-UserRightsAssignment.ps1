<#
.SYNOPSIS
    Creates or updates a GPO to configure User Rights Assignment settings
    aligned with NIST AC-2, AC-3, AC-6, and IA-2 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    User Rights Assignment settings under:

        Computer Configuration →
        Policies →
        Windows Settings →
        Security Settings →
        Local Policies →
        User Rights Assignment

    All settings are variable-driven using a hashtable for easy modification.
    Values must be in SID or "DOMAIN\Group" format.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER UserRights
    Hashtable of user rights and their assigned principals.
    Keys must match the internal privilege names (e.g., SeDenyInteractiveLogonRight).

.EXAMPLE
    .\New-NISTGPO-UserRightsAssignment.ps1 `
        -GpoName "NIST - User Rights Assignment" `
        -TargetOU "OU=Servers,DC=example,DC=com"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO automation
    Category: User Rights Assignment
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$UserRights = @{
        # Logon Restrictions
        "SeDenyInteractiveLogonRight"       = @("DOMAIN\Guests")
        "SeDenyRemoteInteractiveLogonRight" = @("DOMAIN\Guests")

        # RDP Access
        "SeRemoteInteractiveLogonRight"     = @("DOMAIN\Remote Desktop Users")

        # Service Logon
        "SeServiceLogonRight"               = @("DOMAIN\Service Accounts")

        # Privileged Operations
        "SeDebugPrivilege"                  = @()
        "SeTakeOwnershipPrivilege"          = @()
        "SeBackupPrivilege"                 = @("DOMAIN\Backup Operators")
        "SeRestorePrivilege"                = @("DOMAIN\Backup Operators")
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
# Configure User Rights Assignment
# -----------------------------
Write-Host "Configuring User Rights Assignment..." -ForegroundColor Cyan

$baseKey = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\Rights"

foreach ($right in $UserRights.GetEnumerator()) {

    $privilege = $right.Key
    $principals = $right.Value

    Write-Host "Setting $privilege" -ForegroundColor Yellow

    # Convert principals to a comma-separated string
    $value = ($principals -join ",")

    Set-GPRegistryValue -Name $GpoName `
        -Key $baseKey `
        -ValueName $privilege `
        -Type String `
        -Value $value
}

Write-Host "User Rights Assignment configuration complete." -ForegroundColor Green