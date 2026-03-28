# PowerShell Scripts to be used frequently in IT
## Script to automate troubleshooting a network issue
- Asks for an IP and then:
    - Pings the IP.
    - Performs a tracertd.
    - Attempts to get the DNS record of the IP.
    - Outputs the results to a file for record keeping.

## WindowsUpdateTroubleshooter.ps1
- Stops services used for Windows Update.
- Reset Windows Update cache.
- Restarts services used for Windows Update.
- Force a scan for Windows Updates.
- Force install found updates for Windows.

## VMHealthInventory.ps1
- Does a full VM inventory including CPU, RAM, dynamic memory allocation, uptime, heartbeat, disks, network, checkpoints.
- Performs health checks for VMs including:
    - VM state.
    - Heartbeat integration service.
    - Uptime.
    - Checkpoint age.
- Performes optional remediations including:
    - Start stopped VMs.
    - Remove old checkpoints.

## UserProfileLifeCycle.ps1
- Provides full lifecycle visibility of:
    - Local Users
    - Profile folders
    - Last logon
    - Last NTUSER.DAT write
    - Stale profiles
    - Orphaned profiles
- Performs the following remediations and logs every action:
    - Archives profiles before deletion.
    - Only removes stale or orphaned entries.

## ScheduledTaskAuditor.ps1
- Gives visibility into tasks including:
    - State, trigger, run level, user context
    - Last run result
    - Action path validation
    - Script signature validation
- Checks for security & reliability of tasks.

## NISTAlignedPowerGPO.ps1
- Provides NIST SP 800-53 / 800-171 alignment.
- NIST Control AC-11 provides session lock inactivity, password on wake.
- NIST Control PE-13 provides power management, sleep/display timeout, energy-efficient defaults.
- NIST Control SC-28 reduces exposure window by enforcing lock/sleep.