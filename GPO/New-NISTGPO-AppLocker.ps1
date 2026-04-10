<#
.SYNOPSIS
    Creates or updates a GPO to configure AppLocker rules aligned with
    NIST CM-7 and SI-7 requirements.

.DESCRIPTION
    This script creates (or retrieves) a Group Policy Object and configures
    AppLocker rules under:

        Computer Configuration →
        Policies →
        Windows Settings →
        Security Settings →
        Application Control Policies →
        AppLocker

    Rules are defined using a hashtable and converted into an AppLocker
    policy XML, which is then injected into the GPO.

.PARAMETER GpoName
    Name of the GPO to create or modify.

.PARAMETER TargetOU
    Distinguished Name (DN) of the OU where the GPO should be linked.

.PARAMETER AppLockerRules
    Hashtable defining Executable, Script, MSI, and Packaged App rules.

.EXAMPLE
    .\New-NISTGPO-AppLocker.ps1 `
        -GpoName "NIST - AppLocker Policy" `
        -TargetOU "OU=Workstations,DC=example,DC=com"

.NOTES
    Author: SeekNotSought
    Purpose: NIST-aligned GPO automation
    Category: AppLocker
    Version: 1.0
#>

param(
    [Parameter(Mandatory)]
    [string]$GpoName,

    [Parameter(Mandatory)]
    [string]$TargetOU,

    [hashtable]$AppLockerRules = @{

        Executable = @(
            @{
                Name      = "Allow Windows"
                Action    = "Allow"
                Type      = "Publisher"
                Publisher = "*"
                Product   = "*"
                Binary    = "*"
                Version   = "*"
            },
            @{
                Name      = "Allow Program Files"
                Action    = "Allow"
                Type      = "Path"
                Path      = "C:\Program Files\*"
            },
            @{
                Name      = "Allow Windows Folder"
                Action    = "Allow"
                Type      = "Path"
                Path      = "C:\Windows\*"
            }
        )

        Script = @(
            @{
                Name      = "Allow PowerShell Modules"
                Action    = "Allow"
                Type      = "Path"
                Path      = "C:\Windows\System32\WindowsPowerShell\v1.0\Modules\*"
            }
        )

        MSI = @(
            @{
                Name      = "Allow Program Files MSI"
                Action    = "Allow"
                Type      = "Path"
                Path      = "C:\Program Files\*"
            }
        )

        PackagedApp = @(
            @{
                Name      = "Allow All Microsoft Store Apps"
                Action    = "Allow"
                Type      = "Publisher"
                Publisher = "O=Microsoft Corporation, L=Redmond, S=Washington, C=US"
                Product   = "*"
                Binary    = "*"
                Version   = "*"
            }
        )
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
# Build AppLocker Policy XML
# -----------------------------
Write-Host "Building AppLocker policy..." -ForegroundColor Cyan

$policy = New-AppLockerPolicy -XML -RuleType None

foreach ($category in $AppLockerRules.Keys) {

    foreach ($rule in $AppLockerRules[$category]) {

        Write-Host "Adding $category rule: $($rule.Name)" -ForegroundColor Yellow

        switch ($rule.Type) {

            "Path" {
                $entry = New-AppLockerFileRule -Name $rule.Name `
                    -Action $rule.Action `
                    -User "Everyone" `
                    -Path $rule.Path `
                    -RuleType $category
            }

            "Publisher" {
                $entry = New-AppLockerFileRule -Name $rule.Name `
                    -Action $rule.Action `
                    -User "Everyone" `
                    -Publisher $rule.Publisher `
                    -Product $rule.Product `
                    -BinaryName $rule.Binary `
                    -BinaryVersion $rule.Version `
                    -RuleType $category
            }
        }

        $policy.RuleCollections[$category].Add($entry)
    }
}

# -----------------------------
# Apply AppLocker Policy to GPO
# -----------------------------
Write-Host "Applying AppLocker policy to GPO..." -ForegroundColor Cyan

$xml = $policy.ToXml()
Set-GPO -Guid $gpo.Id -Comment "AppLocker policy updated $(Get-Date)"

Set-AppLockerPolicy -XMLPolicy $xml -Merge -ErrorAction Stop

Write-Host "AppLocker configuration complete." -ForegroundColor Green