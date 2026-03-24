<#
.SYNOPSIS
    Collects Hyper-V VM inventory and performs health checks with optional remediation.

.DESCRIPTION
    This script gathers detailed information about Hyper-V virtual machines,
    including resource allocation, state, uptime, checkpoints, and integration
    service status. It can optionally perform remediation actions such as
    starting stopped VMs or removing old checkpoints.

.PARAMETER Remediate
    Enables remediation actions such as starting stopped VMs or removing
    checkpoints older than the specified threshold.

.PARAMETER CheckpointAgeDays
    Specifies the age threshold for checkpoint cleanup when remediation is enabled.

.NOTES
    Author: SeekNotSought
    Version: 1.0.0
    Last Updated: 2026-03-24

.TODO
    - Add CSV/JSON export
    - Add remote Hyper-V host support
    - Add HTML dashboard output
    - Add Teams/Slack notifications
#>

[CmdletBinding()]
param(
    [switch]$Remediate,
    [int]$CheckpointAgeDays = 30
)

function Write-Log {
    param([string]$Message)
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Output "$timestamp`t$Message"
}

function Get-VMInventory {
    Write-Log "Collecting VM inventory..."

    $vms = Get-VM

    $inventory = foreach ($vm in $vms) {
        $disks = Get-VMHardDiskDrive -VMName $vm.Name | Select-Object Path
        $network = Get-VMNetworkAdapter -VMName $vm.Name | Select-Object SwitchName, MacAddress
        $checkpoints = Get-VMSnapshot -VMName $vm.Name -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            Name              = $vm.Name
            State             = $vm.State
            CPUCount          = $vm.ProcessorCount
            MemoryAssignedMB  = $vm.MemoryAssigned / 1MB
            MemoryStartupMB   = $vm.MemoryStartup / 1MB
            DynamicMemory     = $vm.DynamicMemoryEnabled
            Uptime            = $vm.Uptime
            Heartbeat         = (Get-VMIntegrationService -VMName $vm.Name -Name "Heartbeat").PrimaryStatusDescription
            Disks             = $disks.Path -join "; "
            NetworkSwitch     = $network.SwitchName -join "; "
            MACAddress        = $network.MacAddress -join "; "
            CheckpointCount   = $checkpoints.Count
            OldCheckpoints    = $checkpoints | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-$CheckpointAgeDays) }
        }
    }

    return $inventory
}

function Show-VMReport {
    param([array]$Inventory)

    Write-Host "`n===== Hyper-V VM Health & Inventory Report =====" -ForegroundColor Cyan

    foreach ($vm in $Inventory) {
        Write-Host "`nVM Name: $($vm.Name)" -ForegroundColor Yellow
        Write-Host "State:              $($vm.State)"
        Write-Host "CPU Count:          $($vm.CPUCount)"
        Write-Host "Memory (Assigned):  $($vm.MemoryAssignedMB) MB"
        Write-Host "Memory (Startup):   $($vm.MemoryStartupMB) MB"
        Write-Host "Dynamic Memory:     $($vm.DynamicMemory)"
        Write-Host "Uptime:             $($vm.Uptime)"
        Write-Host "Heartbeat:          $($vm.Heartbeat)"
        Write-Host "Disks:              $($vm.Disks)"
        Write-Host "Network Switch:     $($vm.NetworkSwitch)"
        Write-Host "MAC Address:        $($vm.MACAddress)"
        Write-Host "Checkpoints:        $($vm.CheckpointCount)"

        if ($vm.OldCheckpoints.Count -gt 0) {
            Write-Host "Old Checkpoints (> $CheckpointAgeDays days):" -ForegroundColor Red
            $vm.OldCheckpoints | Format-Table Name, CreationTime -AutoSize
        }
    }

    Write-Host "`n==============================================`n"
}

function Repair-VMHealth {
    param([array]$Inventory)

    Write-Log "Starting remediation actions..."

    foreach ($vm in $Inventory) {

        # Start stopped VMs
        if ($vm.State -eq "Off") {
            Write-Log "Starting VM: $($vm.Name)"
            Start-VM -Name $vm.Name -ErrorAction SilentlyContinue
        }

        # Remove old checkpoints
        if ($vm.OldCheckpoints.Count -gt 0) {
            foreach ($cp in $vm.OldCheckpoints) {
                Write-Log "Removing old checkpoint '$($cp.Name)' for VM '$($vm.Name)'"
                Remove-VMSnapshot -VMName $vm.Name -Name $cp.Name -ErrorAction SilentlyContinue
            }
        }
    }

    Write-Log "Remediation complete."
}

# MAIN EXECUTION
$inventory = Get-VMInventory
Show-VMReport -Inventory $inventory

if ($Remediate) {
    Repair-VMHealth -Inventory $inventory
    Write-Log "Rebuilding inventory after remediation..."
    $inventory = Get-VMInventory
    Show-VMReport -Inventory $inventory
}