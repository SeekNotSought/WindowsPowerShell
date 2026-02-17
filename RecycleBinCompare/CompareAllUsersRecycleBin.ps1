#requires -Version 5.1
<#
.SYNOPSIS
    Grabs files in all users's Recycle Bine. Looks at the orginial location to see if the file still exists in that location.

.DESCRIPTION
    This script checks all users's Recycle Bin on the device. It creates a table of all the files in the Recycle Bin and looks to see if the file still exists in the original location. It outputs the results to a csv.

.PARAMETER IPAddress
    The file location to output the csv.

.EXAMPLE
    .\NetworkTroubleshooter.ps1 -OutputFile "C:/Output.csv"
    Runs the script and outputs the csv to the file location

.NOTES
    Author: SeekNotSought
    Version: 0.16
    Last Updated: 2026-02-14

.REQUIREMENTS
    PowerShell 5.1 (required for specific versions of the the Test-Connection commands)
    Windows OS
#>
# Purpose: Compare all user recycle bins to see if the files no longer exist in their original location.

# Requires: Administrator privileges

Write-Host "Enumerating all users' Recycle Bins..." -ForegroundColor Cyan

# Get all SID folders under the system Recycle Bin
$recycleRoot = "C:\$Recycle.Bin"
$sidFolders = Get-ChildItem -Path $recycleRoot -Directory -ErrorAction SilentlyContinue

$results = foreach ($sid in $sidFolders) {

    # Resolve SID to username if possible
    try {
        $user = (New-Object System.Security.Principal.SecurityIdentifier($sid.Name)).Translate([System.Security.Principal.NTAccount]).Value
    } catch {
        $user = "Unknown ($($sid.Name))"
    }

    # Use Shell.Application to read metadata
    $shell = New-Object -ComObject Shell.Application
    $namespace = $shell.Namespace($sid.FullName)

    if ($namespace-eq $null) { continue }

    foreach ($item in $namespace.Items()) {
        [PSCustomObject]@{
            User          = $user
            OriginalName  = $namespace.GetDetailsOf($item, 0)
            OriginalPath  = $namespace.GetDetailsOf($item, 1)
            DeletedDate   = $namespace.GetDetailsOf($item, 2)
            Size          = $namespace.GetDetailsOf($item, 3)
            RecycleBinSID = $sid.Name
            RecycleBinDir = $sid.FullName
        }
    }
}

$results | Format-Table -AutoSize