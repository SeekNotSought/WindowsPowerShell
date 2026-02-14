#requires -Version 5.1
<#
.SYNOPSIS
    Grabs files in the current user's Recycle Bine. Looks at the orginial location to see if the file still exists in that location.

.DESCRIPTION
    This script checks the current user's Recycle Bin. It creates a table of all the files in the Recycle Bin and looks to see if the file still exists in the original location. It outputs the results to a csv.

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