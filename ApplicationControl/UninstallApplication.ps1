<#
.SYNOPSIS
    Uninstalls programs listed in an input file.

.DESCRIPTION
    Reads program names from a file, finds matching uninstallers in the registry,
    detects whether the uninstall command is MSI or EXE, and uninstalls accordingly.

.PARAMETER ProgramList
    Path to a text file containing program names, one per line.

.EXAMPLE
    .\UninstallApplication.ps1 -ProgramList "C:\Temp\Programs.txt"
#>

param(
    [Parameter(Mandatory)]
    [string]$ProgramList
)

# Load program names
$targets = Get-Content -Path $ProgramList | Where-Object { $_.Trim() -ne "" }

# Registry paths to search
$uninstallPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
)

Write-Output "`n=== Starting Uninstall Process ===`n"

foreach ($target in $targets) {

    Write-Output "$(Get-Date): Searching for: $target"

    $matchingApps = foreach ($path in $uninstallPaths) {
        Get-ChildItem $path -ErrorAction SilentlyContinue |
            Get-ItemProperty |
            Where-Object { $_.DisplayName -like "*$target*" }
    }

    if (-not $matchingApps) {
        Write-Warning "$(Get-Date): No installed program found matching: $target"
        continue
    }

    foreach ($app in $matchingApps) {

        $name = $app.DisplayName
        $uninstallString = $app.UninstallString

        Write-Output "`n$(Get-Date): Found: $name"
        Write-Output "$(Get-Date): UninstallString: $uninstallString"

        if (-not $uninstallString) {
            Write-Warning "$(Get-Date): No uninstall command found for $name"
            continue
        }

        # Detect MSI GUID
        if ($uninstallString -match "{[0-9A-Fa-f\-]{36}}") {
            $guid = $matchingApps[0].PSObject.Properties["PSChildName"].Value
            Write-Output "$(Get-Date): Detected MSI uninstall for $name"

            $cmd = "msiexec.exe"
            $msArgs = "/x $guid /qn /norestart"
        }
        else {
            Write-Output "$(Get-Date): Detected EXE uninstall for $name"

            # Some uninstall strings include arguments; split safely
            $exe, $rest = $uninstallString -split "\s+", 2

            # Try common silent switches
            $silentArgs = if ($rest) { "$rest /quiet /norestart" } else { "/quiet /norestart" }

            $cmd = $exe
            $msArgs = $silentArgs
        }

        Write-Output "$(Get-Date): Executing: $cmd $msArgs"

        try {
            Start-Process -FilePath $cmd -ArgumentList $msArgs -Wait -ErrorAction Stop
            Write-Output "$(Get-Date): Successfully uninstalled: $name"
        }
        catch {
            Write-Warning "$(Get-Date): Failed to uninstall $name. Error: $_"
        }
    }
}

Write-Output "`n=== $(Get-Date): Uninstall Process Complete ===`n"
exit