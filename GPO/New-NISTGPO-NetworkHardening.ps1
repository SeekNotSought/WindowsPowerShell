<#
.SYNOPSIS
    Creates or updates a GPO to configure Network hardening Administrative Template
    settings aligned with NIST SC-7 and SC-8 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    Administrative Template settings under:

        Computer Configuration →
        Policies →
        Administrative Templates →
        Network

    All settings are variable-driven using a hashtable for easy modification.
    Registry values correspond to ADMX-backed policies.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER NetworkHardening
    Hashtable of network-hardening settings and their registry values.

.EXAMPLE
    .\New-NISTGPO-NetworkHardening.ps1 `
        -GpoName "NIST - Network Hardening" `
        -TargetOU "OU=Workstations,DC=example,DC=com"

.NOTES
    Author: Carl
    Purpose: NIST-aligned GPO automation
    Category: Administrative Templates – Network
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$NetworkHardening = @{

        # -------------------------
        # LDAP Signing Requirements
        # -------------------------
        "LDAPClientIntegrity" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\Directory UI"
            Type  = "DWord"
            Value = 1   # Require signing
        }

        # -------------------------
        # NTLM Restrictions
        # -------------------------
        "LmCompatibilityLevel" = @{
            Key   = "HKLM\System\CurrentControlSet\Control\Lsa"
            Type  = "DWord"
            Value = 5   # NTLMv2 only
        }

        "RestrictSendingNTLMTraffic" = @{
            Key   = "HKLM\System\CurrentControlSet\Control\Lsa\MSV1_0"
            Type  = "DWord"
            Value = 2   # Deny all NTLM outbound
        }

        # -------------------------
        # Hardened UNC Paths
        # -------------------------
        "RequireMutualAuth" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths"
            Type  = "String"
            Value = "\\*\SYSVOL:RequireMutualAuthentication=1,RequireIntegrity=1"
        }

        "RequireIntegrity" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths"
            Type  = "String"
            Value = "\\*\NETLOGON:RequireMutualAuthentication=1,RequireIntegrity=1"
        }

        # -------------------------
        # SMB Client Hardening
        # -------------------------
        "EnableSecuritySignature" = @{
            Key   = "HKLM\System\CurrentControlSet\Services\LanmanWorkstation\Parameters"
            Type  = "DWord"
            Value = 1
        }

        "RequireSecuritySignature" = @{
            Key   = "HKLM\System\CurrentControlSet\Services\LanmanWorkstation\Parameters"
            Type  = "DWord"
            Value = 1
        }

        # -------------------------
        # SMB Server Hardening
        # -------------------------
        "EnableSecuritySignature_Server" = @{
            Key   = "HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters"
            Type  = "DWord"
            Value = 1
        }

        "RequireSecuritySignature_Server" = @{
            Key   = "HKLM\System\CurrentControlSet\Services\LanmanServer\Parameters"
            Type  = "DWord"
            Value = 1
        }
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
# Apply Network Hardening Settings
# -----------------------------
Write-Host "Configuring Network Hardening Administrative Template settings..." -ForegroundColor Cyan

foreach ($setting in $NetworkHardening.GetEnumerator()) {

    $name  = $setting.Key
    $data  = $setting.Value

    Write-Host "Setting $name = $($data.Value)" -ForegroundColor Yellow

    Set-GPRegistryValue -Name $GpoName `
        -Key $data.Key `
        -ValueName $name `
        -Type $data.Type `
        -Value $data.Value
}

Write-Host "Network Hardening configuration complete." -ForegroundColor Green