<#
.SYNOPSIS
    Update AD group membership for users based on a CSV list.

.DESCRIPTION
    Reads a CSV containing SamAccountName and a comma-separated list of groups.
    Adds users to groups if missing, and can optionally remove users from groups
    not listed (set $EnforceExactMembership = $true).

.PARAMETER CsvPath
    Path to the CSV file.

.PARAMETER EnforceExactMembership
    If $true, user will be removed from any group not listed in the CSV.
#>

param(
    [Parameter(Mandatory)]
    [string]$CsvPath,

    [bool]$EnforceExactMembership = $false
)

Import-Module ActiveDirectory

# Load CSV
$users = Import-Csv -Path $CsvPath

foreach ($entry in $users) {

    $user = Get-ADUser -Identity $entry.SamAccountName -Properties memberOf -ErrorAction SilentlyContinue
    if (-not $user) {
        Write-Warning "User not found: $($entry.SamAccountName)"
        continue
    }

    # Parse groups
    $targetGroups = $entry.Groups -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    foreach ($group in $targetGroups) {
        if (-not (Get-ADGroup -Identity $group -ErrorAction SilentlyContinue)) {
            Write-Warning "Group not found: $group"
            continue
        }

        # Add user if not already a member
        if (-not ($user.MemberOf -contains "CN=$group")) {
            try {
                Add-ADGroupMember -Identity $group -Members $user.SamAccountName -ErrorAction Stop
                Write-Host "Added $($user.SamAccountName) to $group"
            }
            catch {
                Write-Warning "Failed to add $($user.SamAccountName) to ${group}: $_"
            }
        }
    }

    if ($EnforceExactMembership) {
        # Remove user from groups not listed
        $currentGroups = $user.MemberOf | ForEach-Object { (Get-ADGroup $_).Name }

        $groupsToRemove = $currentGroups | Where-Object { $_ -notin $targetGroups }

        foreach ($grp in $groupsToRemove) {
            try {
                Remove-ADGroupMember -Identity $grp -Members $user.SamAccountName -Confirm:$false -ErrorAction Stop
                Write-Host "Removed $($user.SamAccountName) from $grp"
            }
            catch {
                Write-Warning "Failed to remove $($user.SamAccountName) from ${grp}: $_"
            }
        }
    }
}