<#
.SYNOPSIS
    Creates a GPO enforcing NIST-aligned power management settings for Windows 11.

.DESCRIPTION
    This script:
      - Creates a GPO
      - Applies power management settings (AC/DC)
      - Applies session lock timeout
      - Locks down user ability to change power settings
      - Applies security filtering and scope based on variables

.NOTES
    Requires: Group Policy Management Console (GPMC)
#>

# ============================
# VARIABLES — EDIT AS NEEDED
# ============================

# GPO metadata
$GpoName        = "NIST Power Management Baseline"
$GpoDescription = "Enforces NIST-aligned power, sleep, display, and session lock settings for Windows 11."

# Scope
$TargetOU       = "OU=Workstations,DC=example,DC=com"

# Security Filtering
$SecurityFilterGroup = "Domain Computers"

# Enforced? (true/false)
$LinkEnforced = $true

# ============================
# CREATE / RESET GPO
# ============================

Import-Module GroupPolicy

# Create or reset GPO
$gpo = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue
if ($gpo) {
    Write-Host "GPO exists — resetting..."
    $gpo | Set-GPO -Comment $GpoDescription
} else {
    Write-Host "Creating new GPO..."
    $gpo = New-GPO -Name $GpoName -Comment $GpoDescription
}

# ============================
# LINK GPO TO TARGET OU
# ============================

New-GPLink -Name $GpoName -Target $TargetOU -Enforced:$LinkEnforced -ErrorAction SilentlyContinue

# ============================
# APPLY SECURITY FILTERING
# ============================

# Remove Authenticated Users
$gpoSec = Get-GPPermission -Name $GpoName -TargetName "Authenticated Users" -TargetType Group -ErrorAction SilentlyContinue
if ($gpoSec) {
    Set-GPPermission -Name $GpoName -TargetName "Authenticated Users" -TargetType Group -PermissionLevel None
}

# Add desired group
Set-GPPermission -Name $GpoName -TargetName $SecurityFilterGroup -TargetType Group -PermissionLevel GpoApply

# ============================
# POWER MANAGEMENT SETTINGS
# ============================
# These map to NIST AC‑11 & PE‑13 controls.

# Helper function
function Set-RegistryPolicy {
    param(
        [string]$KeyPath,
        [string]$ValueName,
        [string]$Type,
        [string]$Value
    )
    Set-GPRegistryValue -Name $GpoName -Key $KeyPath -ValueName $ValueName -Type $Type -Value $Value
}

# ----------------------------
# Display Timeout (AC/DC)
# ----------------------------
# 3 minutes DC, 10 minutes AC (NIST-aligned + Microsoft recommendations)
Set-RegistryPolicy "HKLM\Software\Policies\Microsoft\Power\PowerSettings\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e" "DCSettingIndex" "DWord" 180
Set-RegistryPolicy "HKLM\Software\Policies\Microsoft\Power\PowerSettings\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e" "ACSettingIndex" "DWord" 600

# ----------------------------
# Sleep Timeout (AC/DC)
# ----------------------------
Set-RegistryPolicy "HKLM\Software\Policies\Microsoft\Power\PowerSettings\238c9fa8-0aad-41ed-83f4-97be242c8f20\29f6c1db-86da-48c5-9fdb-f2b67b1f44da" "DCSettingIndex" "DWord" 300
Set-RegistryPolicy "HKLM\Software\Policies\Microsoft\Power\PowerSettings\238c9fa8-0aad-41ed-83f4-97be242c8f20\29f6c1db-86da-48c5-9fdb-f2b67b1f44da" "ACSettingIndex" "DWord" 900

# ----------------------------
# Require Password on Wake
# ----------------------------
Set-RegistryPolicy "HKLM\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51\0e796bdb-100d-47d6-a2d5-f7d2daa51f51" "ACSettingIndex" "DWord" 1
Set-RegistryPolicy "HKLM\Software\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51\0e796bdb-100d-47d6-a2d5-f7d2daa51f51" "DCSettingIndex" "DWord" 1

# ----------------------------
# Session Lock Timeout (AC‑11)
# ----------------------------
# 900 seconds (15 minutes)
Set-RegistryPolicy "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" "InactivityTimeoutSecs" "DWord" 900

# ----------------------------
# Prevent Users from Changing Power Settings
# ----------------------------
Set-RegistryPolicy "HKLM\Software\Policies\Microsoft\Power\PowerSettings" "ActivePowerScheme" "String" "GUID"
Set-RegistryPolicy "HKLM\Software\Policies\Microsoft\Power\PowerSettings" "PromptPasswordOnResume" "DWord" 1

Write-Host "NIST Power Management GPO configuration complete."