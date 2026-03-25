<#
.SYNOPSIS
    Retrieves user information from a Windows 11 device.

.DESCRIPTION
    This function enumerates:
        - Local user accounts (Get-LocalUser)
        - User profile folders under C:\Users
        - Local group membership for all groups

    Parameters allow filtering the output or exporting results.

.PARAMETER LocalOnly
    Returns only local user accounts.

.PARAMETER ProfilesOnly
    Returns only user profile folders.

.PARAMETER GroupsOnly
    Returns only local group membership.

.PARAMETER ExportCsv
    Exports the selected data to CSV files in the specified directory.

.PARAMETER OutputPath
    Directory where CSV files will be saved when using -ExportCsv.

.EXAMPLE
    Get-AllUsers
    Returns all user-related information.

.EXAMPLE
    Get-AllUsers -LocalOnly
    Returns only local user accounts.

.EXAMPLE
    Get-AllUsers -ExportCsv -OutputPath "C:\Reports"

.NOTES
    Author: SeekNotSought
    Version: 1.1
    Created: 2026-02-22
    Last Updated: 2026-02-22

    Change Log:
        1.0 - Initial script version.
        1.1 - Converted to function and added parameters.

    TODO:
        - Add remote computer support
        - Add JSON export
        - Add logging and verbose levels
        - Add AD user enumeration when domain-joined

.REQUIREMENTS
    PowerShell 5.1 or later
    Windows 10/11
#>

function Get-AllUsers {

    [CmdletBinding()]
    param(
        [switch]$LocalOnly,
        [switch]$ProfilesOnly,
        [switch]$GroupsOnly,

        [switch]$ExportCsv,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )

    # Validate export path
    if ($ExportCsv -and -not $OutputPath) {
        throw "You must specify -OutputPath when using -ExportCsv."
    }

    if ($ExportCsv -and -not (Test-Path $OutputPath)) {
        throw "OutputPath '$OutputPath' does not exist."
    }

    # --- Collect Data ---

    $localUsers = Get-LocalUser | Select-Object Name, Enabled, LastLogon

    $profileUsers = Get-ChildItem "C:\Users" -Directory |
        Where-Object { $_.Name -notin @('Public','Default','Default User','All Users') } |
        Select-Object @{n='Name';e={$_.Name}}, @{n='ProfilePath';e={$_.FullName}}

    $groupMembers = Get-LocalGroup | ForEach-Object {
        $group = $_.Name
        Get-LocalGroupMember -Group $group |
            Select-Object @{n='Group';e={$group}}, Name, ObjectClass
    }

    # --- Filtering Logic ---

    if ($LocalOnly)     { return $localUsers }
    if ($ProfilesOnly)  { return $profileUsers }
    if ($GroupsOnly)    { return $groupMembers }

    # --- Export Logic ---

    if ($ExportCsv) {
        $localUsers    | Export-Csv -Path (Join-Path $OutputPath "LocalUsers.csv") -NoTypeInformation
        $profileUsers  | Export-Csv -Path (Join-Path $OutputPath "ProfileUsers.csv") -NoTypeInformation
        $groupMembers  | Export-Csv -Path (Join-Path $OutputPath "GroupMembers.csv") -NoTypeInformation
    }

    # --- Default Output ---

    [PSCustomObject]@{
        LocalUsers    = $localUsers
        ProfileUsers  = $profileUsers
        GroupMembers  = $groupMembers
    }
}