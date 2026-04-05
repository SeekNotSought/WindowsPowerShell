<#
.SYNOPSIS
    Creates or updates a GPO to configure Windows Firewall with Advanced Security
    aligned with NIST SC-7 and SC-18 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    Windows Firewall profiles and optional inbound/outbound rules under:

        Computer Configuration →
        Policies →
        Windows Settings →
        Security Settings →
        Windows Firewall with Advanced Security

    All settings are variable-driven using hashtables for easy modification.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER FirewallProfiles
    Hashtable defining Domain, Private, and Public profile settings.

.PARAMETER FirewallRules
    Optional array of firewall rules to create (inbound or outbound).

.EXAMPLE
    .\New-NISTGPO-Firewall.ps1 `
        -GpoName "NIST - Firewall Policy" `
        -TargetOU "OU=Servers,DC=example,DC=com"

.NOTES
    Author: Carl
    Purpose: NIST-aligned GPO automation
    Category: Windows Firewall
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$FirewallProfiles = @{
        "Domain" = @{
            "State"        = "on"
            "Inbound"      = "block"
            "Outbound"     = "allow"
            "LogFile"      = "%systemroot%\system32\logfiles\firewall\domainfw.log"
            "LogDropped"   = "enable"
            "LogSuccessful"= "disable"
        }
        "Private" = @{
            "State"        = "on"
            "Inbound"      = "block"
            "Outbound"     = "allow"
            "LogFile"      = "%systemroot%\system32\logfiles\firewall\privatefw.log"
            "LogDropped"   = "enable"
            "LogSuccessful"= "disable"
        }
        "Public" = @{
            "State"        = "on"
            "Inbound"      = "block"
            "Outbound"     = "allow"
            "LogFile"      = "%systemroot%\system32\logfiles\firewall\publicfw.log"
            "LogDropped"   = "enable"
            "LogSuccessful"= "disable"
        }
    },

    [array]$FirewallRules = @(
        # Example rule (disabled by default)
        # @{
        #     "Name"        = "Allow RDP"
        #     "Direction"   = "in"
        #     "Action"      = "allow"
        #     "Protocol"    = "TCP"
        #     "LocalPort"   = "3389"
        #     "RemoteIP"    = "any"
        #     "Profile"     = "domain,private"
        # }
    )
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
# Configure Firewall Profiles
# -----------------------------
Write-Host "Configuring Windows Firewall profiles..." -ForegroundColor Cyan

foreach ($profile in $FirewallProfiles.GetEnumerator()) {

    $name = $profile.Key
    $settings = $profile.Value

    Write-Host "Configuring $name profile..." -ForegroundColor Yellow

    # State
    netsh advfirewall set $name state $($settings["State"]) | Out-Null

    # Inbound / Outbound
    netsh advfirewall set $name firewallpolicy `
        $($settings["Inbound"]) `
        $($settings["Outbound"]) | Out-Null

    # Logging
    netsh advfirewall set $name logging filename="$($settings["LogFile"])" | Out-Null
    netsh advfirewall set $name logging dropped=$($settings["LogDropped"]) | Out-Null
    netsh advfirewall set $name logging allowed=$($settings["LogSuccessful"]) | Out-Null
}

# -----------------------------
# Configure Firewall Rules
# -----------------------------
if ($FirewallRules.Count -gt 0) {
    Write-Host "Configuring custom firewall rules..." -ForegroundColor Cyan

    foreach ($rule in $FirewallRules) {

        Write-Host "Adding rule: $($rule["Name"])" -ForegroundColor Yellow

        $cmd = "advfirewall firewall add rule name=""$($rule["Name"])"" " +
               "dir=$($rule["Direction"]) action=$($rule["Action"]) " +
               "protocol=$($rule["Protocol"]) localport=$($rule["LocalPort"]) " +
               "remoteip=$($rule["RemoteIP"]) profile=$($rule["Profile"])"

        netsh $cmd | Out-Null
    }
}

Write-Host "Windows Firewall configuration complete." -ForegroundColor Green
