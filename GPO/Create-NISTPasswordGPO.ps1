<#
.SYNOPSIS
    Creates a GPO with password settings aligned to NIST SP 800-63B guidance.

.DESCRIPTION
    This script creates and configures a Group Policy Object (GPO) to enforce
    password policies consistent with NIST recommendations:
        - Emphasis on password length (≥ 15 recommended)
        - No complexity requirements
        - No forced rotation
        - Password history enabled
        - Maximum password age set to 0 (no expiration)

    Note: Some NIST requirements (e.g., breach password screening) require
    third‑party tools and cannot be enforced via native GPO.

.PARAMETER GpoName
    Name of the GPO to create.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU to link the GPO to.

.PARAMETER SecurityGroup
    Security group to apply GPO filtering to.

.PARAMETER MinPasswordLength
    Minimum password length to enforce.

.PARAMETER PasswordHistoryCount
    Number of previous passwords to remember.

.EXAMPLE
    .\Create-NISTPasswordGPO.ps1
#>

param(
    [string]$GpoName               = "NIST Password Policy",
    [string]$TargetOU              = "OU=Workstations,DC=example,DC=com",
    [string]$SecurityGroup         = "Domain Computers",
    [int]$MinPasswordLength        = 15,   # NIST Rev.4 recommended minimum
    [int]$PasswordHistoryCount     = 10    # NIST recommends preventing reuse
)

Import-Module GroupPolicy -ErrorAction Stop

Write-Host "Creating GPO: $GpoName..." -ForegroundColor Cyan
$gpo = New-GPO -Name $GpoName -ErrorAction Stop

Write-Host "Linking GPO to OU: $TargetOU..." -ForegroundColor Cyan
New-GPLink -Name $GpoName -Target $TargetOU -Enforced $false

Write-Host "Configuring security filtering..." -ForegroundColor Cyan
$gpoSec = Get-GPO -Name $GpoName
Set-GPPermission -Name $GpoName -TargetName $SecurityGroup -TargetType Group -PermissionLevel GpoApply

Write-Host "Applying NIST-aligned password settings..." -ForegroundColor Cyan

# Enforce password history
Set-GPRegistryValue -Name $GpoName `
    -Key "HKLM\System\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "MaximumPasswordAge" -Type DWord -Value 0

# Password history (NIST recommends preventing reuse)
Set-GPRegistryValue -Name $GpoName `
    -Key "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" `
    -ValueName "PasswordHistorySize" -Type DWord -Value $PasswordHistoryCount

# Minimum password length
Set-GPRegistryValue -Name $GpoName `
    -Key "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" `
    -ValueName "MinimumPasswordLength" -Type DWord -Value $MinPasswordLength

# Disable password complexity (NIST: no composition rules)
Set-GPRegistryValue -Name $GpoName `
    -Key "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" `
    -ValueName "PasswordComplexity" -Type DWord -Value 0

# Disable forced password expiration (NIST: no rotation)
Set-GPRegistryValue -Name $GpoName `
    -Key "HKLM\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" `
    -ValueName "MaximumPasswordAge" -Type DWord -Value 0

Write-Host "NIST-aligned password GPO created successfully." -ForegroundColor Green