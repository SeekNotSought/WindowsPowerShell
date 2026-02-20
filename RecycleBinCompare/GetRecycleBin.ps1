#requires -Version 5.1

function Get-RecycleBinItem {
    <#
    .SYNOPSIS
        Returns the contents of the current user's Recycle Bin.

    .DESCRIPTION
        Uses the Shell.Application COM object to enumerate items in the Recycle Bin and outputs the objects containing original name, path, deletion date, and size.

    .EXAMPLE
        Get-RecycleBinItem | Format-Table -AutoSize

    .NOTES
        Author: SeekNotSought
        Version: 0.20
        Last Updated: 2026-02-18

    .REQUIREMENTS
        PowerShell 5.1 (required for specific versions of the the Test-Connection commands)
        Windows OS
    #>

    # List the contents of the recycling bin.
    $Shell = New-object -ComObject Shell.Application
    $RecycleBin = $Shell.Namespace(0xA) # 0xA = Recycle Bin
    
    if (-not $RecycleBin) {
        Write-Warning "Unable to access the Recycle Bin."
        return
    }
    
    $Items = $RecycleBin.Items()
    Write-Output "About to loop through each item in the Recycle Bin."
    foreach ($Item in $Items) {
        $OriginalName = $RecycleBin.GetDetailsOf($Item, 0)
        $OriginalPath = $RecycleBin.GetDetailsOf($Item, 1)
        $DeletedDate = $RecycleBin.GetDetailsOf($Item, 2)
        $Size = $RecycleBin.GetDetailsOf($Item, 3)

        # Combine the path with the name to test existence.
        $FullOriginalPath = Join-Path -Path $OriginalPath -ChildPath $OriginalName

        [PSCustomObject]@{
            OriginalName                = $OriginalName
            OriginalPath                = $OriginalPath
            DeletedDate                 = $DeletedDate
            Size                        = $Size
            FullOriginalPath            = $FullOriginalPath
            ExistsInOriginalLocation    = Test-Path -LiteralPath $FullOriginalPath

        }
    }
}

