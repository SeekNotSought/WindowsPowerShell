<#
.SYNOPSIS
    Creates or updates a GPO to configure Security Options settings
    aligned with NIST AC-17, IA-2, SC-7, and SC-28 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    Security Options under:

        Computer Configuration →
        Policies →
        Windows Settings →
        Security Settings →
        Local Policies →
        Security Options

    All settings are variable-driven using a hashtable for easy modification.
    Values are applied using secedit-compatible registry keys.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER SecurityOptions
    Hashtable of Security Options and their registry values.
    Keys must match the internal registry-based policy names.

.EXAMPLE
    .\New-NISTGPO-SecurityOptions.ps1 `
        -GpoName "NIST - Security Options" `
        -TargetOU "OU=Servers,DC=example,DC=com"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO automation
    Category: Security Options
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$SecurityOptions = @{

        # -------------------------
        # Interactive Logon
        # -------------------------
        "DontDisplayLastUserName"                = 1
        "DisableCAD"                             = 0
        "LegalNoticeCaption"                     = "NOTICE"
        "LegalNoticeText"                        = "Unauthorized access is prohibited."

        # -------------------------
        # Network Security
        # -------------------------
        "LDAPClientIntegrity"                    = 1   # Require signing
        "LmCompatibilityLevel"                   = 5   # NTLMv2 only
        "NoLMHash"                               = 1
        "NTLMMinClientSec"                       = 537395200
        "NTLMMinServerSec"                       = 537395200

        # -------------------------
        # SMB / LAN Manager
        # -------------------------
        "RequireSecuritySignature"               = 1
        "EnableSecuritySignature"                = 1

        # -------------------------
        # Devices
        # -------------------------
        "AllocateDASD"                           = 0
        "AllocateFloppies"                       = 0

        # -------------------------
        # Accounts
        # -------------------------
        "LimitBlankPasswordUse"                  = 1

        # -------------------------
        # Shutdown Behavior
        # -------------------------
        "ShutdownWithoutLogon"                   = 0

        # -------------------------
        # UAC
        # -------------------------
        "ConsentPromptBehaviorAdmin"             = 2
        "EnableLUA"                              = 1
        "PromptOnSecureDesktop"                  = 1
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
# Configure Security Options
# -----------------------------
Write-Host "Configuring Security Options..." -ForegroundColor Cyan

$baseKey = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System"

foreach ($option in $SecurityOptions.GetEnumerator()) {

    $name  = $option.Key
    $value = $option.Value

    Write-Host "Setting $name = $value" -ForegroundColor Yellow

    # Determine registry type
    $type = if ($value -is [int]) { "DWord" } else { "String" }

    Set-GPRegistryValue -Name $GpoName `
        -Key $baseKey `
        -ValueName $name `
        -Type $type `
        -Value $value
}

Write-Host "Security Options configuration complete." -ForegroundColor Green