<#
.SYNOPSIS
    Verifies NIST-aligned GPO baseline compliance across Windows systems.

.DESCRIPTION
    This script checks whether a system complies with the NIST baseline
    implemented by Scripts 1–10. It validates:

        1. Account Lockout Policy
        2. Audit Policy (Legacy)
        3. Advanced Audit Policy
        4. User Rights Assignment
        5. Security Options
        6. Windows Firewall Profiles
        7. System Hardening (Admin Templates)
        8. Network Hardening (Admin Templates)
        9. Windows Components Hardening
       10. AppLocker Policy

    Results are output to screen and exported to CSV.

.PARAMETER ComputerName
    One or more computers to verify.

.PARAMETER OutputPath
    Path to save the compliance CSV report.

.EXAMPLE
    .\New-NISTGPO-BaselineComplianceVerification.ps1 `
        -ComputerName "SERVER01","SERVER02" `
        -OutputPath "C:\Reports\NIST-Compliance.csv"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned baseline compliance verification
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string[]]$ComputerName,

    [Parameter(Mandatory)]
    [string]$OutputPath
)

# -----------------------------
# Helper: Create result object
# -----------------------------
function New-ComplianceResult {
    param(
        [string]$Computer,
        [string]$Control,
        [string]$Expected,
        [string]$Actual,
        [bool]$Compliant
    )

    [PSCustomObject]@{
        Computer  = $Computer
        Control   = $Control
        Expected  = $Expected
        Actual    = $Actual
        Compliant = if ($Compliant) { "PASS" } else { "FAIL" }
    }
}

$results = @()

# -----------------------------
# Begin Compliance Checks
# -----------------------------
foreach ($computer in $ComputerName) {

    Write-Host "`nChecking compliance on $computer..." -ForegroundColor Cyan

    # ============================================================
    # 1. Account Lockout Policy
    # ============================================================
    $expected = @{
        "LockoutThreshold" = 5
        "LockoutDuration"  = 15
        "ResetLockoutCount"= 15
    }

    foreach ($setting in $expected.Keys) {
        $actual = Invoke-Command -ComputerName $computer -ScriptBlock {
            param($setting)
            (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters").$setting
        } -ArgumentList $setting

        $results += New-ComplianceResult -Computer $computer `
            -Control "Account Lockout: $setting" `
            -Expected $expected[$setting] `
            -Actual $actual `
            -Compliant ($actual -eq $expected[$setting])
    }

    # ============================================================
    # 2. Audit Policy (Legacy)
    # ============================================================
    $legacyAudit = @{
        "AuditAccountLogon"      = 3
        "AuditAccountManagement" = 3
        "AuditLogonEvents"       = 3
        "AuditPolicyChange"      = 3
        "AuditSystemEvents"      = 3
    }

    foreach ($setting in $legacyAudit.Keys) {
        $actual = Invoke-Command -ComputerName $computer -ScriptBlock {
            param($setting)
            (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit").$setting
        } -ArgumentList $setting

        $results += New-ComplianceResult -Computer $computer `
            -Control "Legacy Audit: $setting" `
            -Expected $legacyAudit[$setting] `
            -Actual $actual `
            -Compliant ($actual -eq $legacyAudit[$setting])
    }

    # ============================================================
    # 3. Advanced Audit Policy
    # ============================================================
    $advAudit = @(
        "Credential Validation",
        "Logon",
        "Account Lockout",
        "Process Creation",
        "Security System Extension",
        "System Integrity"
    )

    foreach ($subcategory in $advAudit) {

        $actual = Invoke-Command -ComputerName $computer -ScriptBlock {
            param($subcategory)
            auditpol.exe /get /subcategory:"$subcategory" | Select-String "Success" | Out-String
        } -ArgumentList $subcategory

        $expected = "Success and Failure"

        $results += New-ComplianceResult -Computer $computer `
            -Control "Advanced Audit: $subcategory" `
            -Expected $expected `
            -Actual $actual.Trim() `
            -Compliant ($actual -match "Success\s+Failure")
    }

    # ============================================================
    # 4. User Rights Assignment
    # ============================================================
    $userRights = @{
        "SeDenyInteractiveLogonRight" = "Guests"
        "SeRemoteInteractiveLogonRight" = "Remote Desktop Users"
    }

    foreach ($right in $userRights.Keys) {

        $actual = Invoke-Command -ComputerName $computer -ScriptBlock {
            param($right)
            secedit.exe /export /cfg C:\Windows\Temp\secpol.cfg | Out-Null
            (Select-String -Path C:\Windows\Temp\secpol.cfg -Pattern $right).ToString()
        } -ArgumentList $right

        $results += New-ComplianceResult -Computer $computer `
            -Control "User Right: $right" `
            -Expected $userRights[$right] `
            -Actual $actual `
            -Compliant ($actual -match $userRights[$right])
    }

    # ============================================================
    # 5. Security Options
    # ============================================================
    $securityOptions = @{
        "DontDisplayLastUserName" = 1
        "EnableLUA"               = 1
    }

    foreach ($setting in $securityOptions.Keys) {

        $actual = Invoke-Command -ComputerName $computer -ScriptBlock {
            param($setting)
            (Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System").$setting
        } -ArgumentList $setting

        $results += New-ComplianceResult -Computer $computer `
            -Control "Security Option: $setting" `
            -Expected $securityOptions[$setting] `
            -Actual $actual `
            -Compliant ($actual -eq $securityOptions[$setting])
    }

    # ============================================================
    # 6. Windows Firewall Profiles
    # ============================================================
    $fwProfiles = @("Domain","Private","Public")

    foreach ($profile in $fwProfiles) {

        $actual = Invoke-Command -ComputerName $computer -ScriptBlock {
            param($profile)
            netsh advfirewall show $profile | Select-String "State" | Out-String
        } -ArgumentList $profile

        $results += New-ComplianceResult -Computer $computer `
            -Control "Firewall Profile: $profile" `
            -Expected "ON" `
            -Actual $actual.Trim() `
            -Compliant ($actual -match "ON")
    }

    # ============================================================
    # 7–10. System, Network, Windows Components, AppLocker
    # (Representative checks — expandable)
    # ============================================================

    $registryChecks = @{
        "DisableCMD" = "HKLM:\Software\Policies\Microsoft\Windows\System"
        "LmCompatibilityLevel" = "HKLM:\System\CurrentControlSet\Control\Lsa"
        "EnableSmartScreen" = "HKLM:\Software\Policies\Microsoft\Windows\System"
        "AppLockerPolicy" = "HKLM:\Software\Policies\Microsoft\Windows\SrpV2"
    }

    foreach ($setting in $registryChecks.Keys) {

        $actual = Invoke-Command -ComputerName $computer -ScriptBlock {
            param($path,$setting)
            try {
                (Get-ItemProperty $path).$setting
            } catch {
                "Not Found"
            }
        } -ArgumentList $registryChecks[$setting], $setting

        $results += New-ComplianceResult -Computer $computer `
            -Control "Registry Check: $setting" `
            -Expected "Configured" `
            -Actual $actual `
            -Compliant ($actual -ne "Not Found")
    }
}

# -----------------------------
# Export Results
# -----------------------------
Write-Host "`nExporting compliance report to $OutputPath" -ForegroundColor Cyan
$results | Export-Csv -Path $OutputPath -NoTypeInformation

Write-Host "Baseline compliance verification complete." -ForegroundColor Green