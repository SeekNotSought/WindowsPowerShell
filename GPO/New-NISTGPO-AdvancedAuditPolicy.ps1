<#
.SYNOPSIS
    Creates or updates a GPO to configure Advanced Audit Policy settings
    aligned with NIST AU-2, AU-6, AU-12, AC-2, and AC-3 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    granular Advanced Audit Policy subcategories under:

        Computer Configuration →
        Policies →
        Windows Settings →
        Security Settings →
        Advanced Audit Policy Configuration →
        Audit Policies

    All settings are variable-driven using a hashtable for easy modification.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER AuditSubcategories
    Hashtable of audit subcategories and their desired values:
        0 = No Auditing
        1 = Success
        2 = Failure
        3 = Success and Failure

.EXAMPLE
    .\New-NISTGPO-AdvancedAuditPolicy.ps1 `
        -GpoName "NIST - Advanced Audit Policy" `
        -TargetOU "OU=Servers,DC=example,DC=com"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO automation
    Category: Advanced Audit Policy
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$AuditSubcategories = @{
        # Account Logon
        "Credential Validation"                = 3
        "Kerberos Authentication Service"      = 3
        "Kerberos Service Ticket Operations"   = 3

        # Account Management
        "User Account Management"              = 3
        "Computer Account Management"          = 3
        "Security Group Management"            = 3
        "Distribution Group Management"        = 3
        "Other Account Management Events"      = 3

        # Logon/Logoff
        "Logon"                                = 3
        "Logoff"                               = 3
        "Account Lockout"                      = 3
        "Special Logon"                        = 3
        "Other Logon/Logoff Events"            = 3

        # Object Access
        "File System"                          = 2
        "Registry"                             = 2
        "Kernel Object"                        = 2
        "SAM"                                  = 2
        "Certification Services"               = 2
        "Application Generated"                = 2
        "Handle Manipulation"                  = 2
        "Other Object Access Events"           = 2

        # Policy Change
        "Audit Policy Change"                  = 3
        "Authentication Policy Change"         = 3
        "Authorization Policy Change"          = 3
        "MPSSVC Rule-Level Policy Change"      = 3
        "Filtering Platform Policy Change"     = 3

        # Privilege Use
        "Sensitive Privilege Use"              = 3
        "Non Sensitive Privilege Use"          = 1
        "Other Privilege Use Events"           = 1

        # Detailed Tracking
        "Process Creation"                     = 3
        "Process Termination"                  = 1
        "DPAPI Activity"                       = 1
        "RPC Events"                           = 1

        # System
        "Security State Change"                = 3
        "Security System Extension"            = 3
        "System Integrity"                     = 3
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
# Configure Advanced Audit Policy
# -----------------------------
Write-Host "Configuring Advanced Audit Policy settings..." -ForegroundColor Cyan

foreach ($subcategory in $AuditSubcategories.GetEnumerator()) {

    $name  = $subcategory.Key
    $value = [int]$subcategory.Value

    Write-Host "Setting '$name' = $value" -ForegroundColor Yellow

    AuditPol.exe /set /subcategory:"$name" /success:$(if ($value -band 1) {"enable"} else {"disable"}) `
                                           /failure:$(if ($value -band 2) {"enable"} else {"disable"}) `
                                           /quiet
}

Write-Host "Advanced Audit Policy configuration complete." -ForegroundColor Green