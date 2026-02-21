#requires -Version 5.1
<#
.SYNOPSIS
    Grabs files in all users's Recycle Bine. Looks at the orginial location to see if the file still exists in that location.

.DESCRIPTION
    This script checks all users's Recycle Bin on the device. It creates a table of all the files in the Recycle Bin and looks to see if the file still exists in the original location. It outputs the results to a csv.

.PARAMETER IPAddress
    The file location to output the csv.

.EXAMPLE
    .\GetAlRecycleBins.ps1

.NOTES
    Author: SeekNotSought
    Version: 0.20
    Last Updated: 2026-02-18

.REQUIREMENTS
    PowerShell 5.1 (required for specific versions of the the Test-Connection commands)
    Windows OS
    Administrator privileges
#>

# Purpose: Compare all user recycle bins to see if the files no longer exist in their original location.

Write-Host "Enumerating all users' Recycle Bins..." -ForegroundColor Cyan

$usersPath = "C:\Users"
$results = @()

# Get all real user profiles (skip system profiles)
$profiles = Get-ChildItem $usersPath -Directory |
    Where-Object { Test-Path "$($_.FullName)\NTUSER.DAT" }

foreach ($profile in $profiles) {

    $userName = $profile.Name
    $hivePath = "$($profile.FullName)\NTUSER.DAT"
    $tempHive = "HKU\TempHive_$userName"

    Write-Host "Loading hive for $userName..." -ForegroundColor Yellow

    # Load the user's registry hive
    reg load $tempHive $hivePath | Out-Null

    try {
        # Create a Shell.Application COM object
        $shell = New-Object -ComObject Shell.Application

        # Open the Recycle Bin namespace for THIS user
        # 0xA = CSIDL_BITBUCKET (Recycle Bin)
        $recycleBin = $shell.Namespace(0xA)

        if ($null -eq $recycleBin) {
            Write-Host "No Recycle Bin namespace for $userName" -ForegroundColor DarkGray
            continue
        }

        $items = $recycleBin.Items()

        foreach ($item in $items) {
            $results += [PSCustomObject]@{
                User         = $userName
                Name         = $recycleBin.GetDetailsOf($item, 0)
                OriginalPath = $recycleBin.GetDetailsOf($item, 1)
                DeletedDate  = $recycleBin.GetDetailsOf($item, 2)
                Size         = $recycleBin.GetDetailsOf($item, 3)
            }
        }
    }
    catch {
        Write-Host "Error reading Recycle Bin for ${userName}: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        # Unload the hive
        Write-Host "Unloading hive for $userName..." -ForegroundColor DarkYellow
        reg unload $tempHive | Out-Null
    }
}

Write-Host "`nCompleted." -ForegroundColor Green
$results | Format-Table -AutoSize