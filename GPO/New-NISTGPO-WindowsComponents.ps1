<#
.SYNOPSIS
    Creates or updates a GPO to configure Windows Components hardening settings
    aligned with NIST SC-7, SC-18, SI-2, and SI-3 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    Administrative Template settings under:

        Computer Configuration →
        Policies →
        Administrative Templates →
        Windows Components

    All settings are variable-driven using a hashtable for easy modification.
    Registry values correspond to ADMX-backed policies.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER WindowsComponents
    Hashtable of Windows Components settings and their registry values.

.EXAMPLE
    .\New-NISTGPO-WindowsComponents.ps1 `
        -GpoName "NIST - Windows Components Hardening" `
        -TargetOU "OU=Workstations,DC=example,DC=com"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO automation
    Category: Administrative Templates – Windows Components
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$WindowsComponents = @{

        # ---------------------------------------------------------
        # Windows Defender Antivirus
        # ---------------------------------------------------------
        "DisableAntiSpyware" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows Defender"
            Type  = "DWord"
            Value = 0   # Ensure Defender is enabled
        }

        "DisableRealtimeMonitoring" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
            Type  = "DWord"
            Value = 0
        }

        "DisableBehaviorMonitoring" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows Defender\Real-Time Protection"
            Type  = "DWord"
            Value = 0
        }

        # ---------------------------------------------------------
        # SmartScreen
        # ---------------------------------------------------------
        "EnableSmartScreen" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\System"
            Type  = "DWord"
            Value = 1
        }

        "ShellSmartScreenLevel" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\System"
            Type  = "String"
            Value = "Block"
        }

        # ---------------------------------------------------------
        # Windows Update
        # ---------------------------------------------------------
        "NoAutoUpdate" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"
            Type  = "DWord"
            Value = 0
        }

        "AUOptions" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU"
            Type  = "DWord"
            Value = 4   # Auto download & schedule install
        }

        # ---------------------------------------------------------
        # Remote Desktop Services
        # ---------------------------------------------------------
        "fDenyTSConnections" = @{
            Key   = "HKLM\System\CurrentControlSet\Control\Terminal Server"
            Type  = "DWord"
            Value = 1   # Disable RDP unless explicitly enabled elsewhere
        }

        # ---------------------------------------------------------
        # Credential Guard / Device Guard
        # ---------------------------------------------------------
        "EnableVirtualizationBasedSecurity" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard"
            Type  = "DWord"
            Value = 1
        }

        "RequirePlatformSecurityFeatures" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\DeviceGuard"
            Type  = "DWord"
            Value = 1   # Secure Boot
        }

        "LsaCfgFlags" = @{
            Key   = "HKLM\System\CurrentControlSet\Control\Lsa"
            Type  = "DWord"
            Value = 1   # Credential Guard
        }

        # ---------------------------------------------------------
        # Windows Installer Restrictions
        # ---------------------------------------------------------
        "DisableMSI" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\Installer"
            Type  = "DWord"
            Value = 2   # Disable MSI for non-admins
        }

        # ---------------------------------------------------------
        # Exploit Guard
        # ---------------------------------------------------------
        "ExploitGuard_ASR" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules"
            Type  = "String"
            Value = "D4F940AB-401B-4EFC-AADC-AD5F3C50688A=1"
        }

        # ---------------------------------------------------------
        # Windows Remote Management (WinRM)
        # ---------------------------------------------------------
        "AllowUnencryptedTraffic" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\WinRM\Client"
            Type  = "DWord"
            Value = 0
        }

        "AllowBasic" = @{
            Key   = "HKLM\Software\Policies\Microsoft\Windows\WinRM\Client"
            Type  = "DWord"
            Value = 0
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
# Apply Windows Components Settings
# -----------------------------
Write-Host "Configuring Windows Components Administrative Template settings..." -ForegroundColor Cyan

foreach ($setting in $WindowsComponents.GetEnumerator()) {

    $name  = $setting.Key
    $data  = $setting.Value

    Write-Host "Setting $name = $($data.Value)" -ForegroundColor Yellow

    Set-GPRegistryValue -Name $GpoName `
        -Key $data.Key `
        -ValueName $name `
        -Type $data.Type `
        -Value $data.Value
}

Write-Host "Windows Components configuration complete." -ForegroundColor Green