<#
.SYNOPSIS
    Retrieves all shutdown‑related events from a Windows 11 device.

.DESCRIPTION
    Queries the System event log for shutdown, restart, power loss,
    unexpected shutdowns, and user‑initiated shutdown events.

.PARAMETER StartTime
    Optional. Only return events after this date/time.

.PARAMETER EndTime
    Optional. Only return events before this date/time.

.PARAMETER ExportPath
    Optional. If provided, exports results to CSV.

.EXAMPLE
    Get-ShutdownEvents

.EXAMPLE
    Get-ShutdownEvents -StartTime (Get-Date).AddDays(-7)

.EXAMPLE
    Get-ShutdownEvents -ExportPath "C:\Temp\ShutdownEvents.csv"
#>

function Get-ShutdownEvents {
    [CmdletBinding()]
    param(
        [datetime]$StartTime,
        [datetime]$EndTime,
        [string]$ExportPath
    )

    # Event IDs related to shutdown/restart
    $EventIDs = @(
        41,   # Kernel-Power: unexpected shutdown
        1074, # User-initiated shutdown/restart
        1076, # Reason for unexpected shutdown
        6005, # Event log service started (boot)
        6006, # Event log service stopped (shutdown)
        6008, # Unexpected shutdown
        6013  # System uptime
    )

    $Filter = @{
        LogName = 'System'
        Id      = $EventIDs
    }

    if ($StartTime) { $Filter.StartTime = $StartTime }
    if ($EndTime)   { $Filter.EndTime   = $EndTime }

    $events = Get-WinEvent -FilterHashtable $Filter -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, Id, LevelDisplayName, ProviderName, Message

    if ($ExportPath) {
        try {
            $events | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
            Write-Host "Exported shutdown events to $ExportPath"
        }
        catch {
            Write-Warning "Failed to export CSV: $($_.Exception.Message)"
        }
    }

    return $events
}