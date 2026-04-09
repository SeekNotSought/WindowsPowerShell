<#
.SYNOPSIS
    Creates or updates a GPO to configure System hardening Administrative Template
    settings aligned with NIST CM-6, SC-4, SC-5, and SC-7 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    Administrative Template settings under:

        Computer Configuration →
        Policies →
        Administrative Templates →
        System

    All settings are variable-driven using a hashtable for easy modification.
    Registry values correspond to ADMX-backed policies.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER SystemHardening
    Hashtable of system-hardening settings and their registry values.

.EXAMPLE
    .\New-NISTGPO-SystemHardening.ps1 `
        -GpoName "NIST - System Hardening" `
        -TargetOU "OU=Workstations,DC=example,DC=com"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO automation
    Category: Administrative Templates – System
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$SystemHardening = @{

        # -------------------------
        # Autoplay / Autorun
        # -------------------------
        "NoDriveTypeAutoRun" = @{
            Key   = "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
            Type  = "DWord"
            Value = 255   # Disable Autoplay on all drives
        }

        # -------------------------
        # Windows Script Host
        # -------------------------
        "EnableWSH" = @{
            Key   = "HKLM\Software\Microsoft\Windows Script Host\Settings"
            Type  = "DWord"
            Value = 0     # Disable Windows Script Host
        }

        # -------------------------
        # Device Installation Restrictions
        # -------------------------
        "DenyDeviceInstall" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
            Type  = "DWord"
            Value = 1     # Prevent installation of unauthorized devices
        }

        # -------------------------
        # Remote Desktop Hardening
        # -------------------------
        "DisableRDPRedirection" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services"
            Type  = "DWord"
            Value = 1     # Disable drive redirection
        }

        "DisableRDPClipboard" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows NT\Terminal Services"
            Type  = "DWord"
            Value = 1     # Disable clipboard redirection
        }

        # -------------------------
        # Command-Line Hardening
        # -------------------------
        "DisableCMD" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\System"
            Type  = "DWord"
            Value = 2     # Disable CMD except for scripts
        }

        "DisablePowerShellTranscription" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\PowerShell\Transcription"
            Type  = "DWord"
            Value = 1     # Enable transcription (hardening)
        }

        # -------------------------
        # Error Reporting
        # -------------------------
        "DisableErrorReporting" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting"
            Type  = "DWord"
            Value = 1     # Disable error reporting
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
# Apply System Hardening Settings
# -----------------------------
Write-Host "Configuring System Hardening Administrative Template settings..." -ForegroundColor Cyan

foreach ($setting in $SystemHardening.GetEnumerator()) {

    $name  = $setting.Key
    $data  = $setting.Value

    Write-Host "Setting $name = $($data.Value)" -ForegroundColor Yellow

    Set-GPRegistryValue -Name $GpoName `
        -Key $data.Key `
        -ValueName $name `
        -Type $data.Type `
        -Value $data.Value
}

Write-Host "System Hardening configuration complete." -ForegroundColor Green