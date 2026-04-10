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

## Create-NISTPasswordGPO.ps1
- Creates a GPO for passwords:
    - The script defaults the password length to 15 according to NIST Rev. 4.
    - The script defaults the complexity to 0 in alignment with NIST.
    - The script defaults the minimum password age to 0.
    - The script prevents reusing the last 10 passwords by default.

## New-NISTGPOP-AccountLockout.ps1
- Creates a GPO to:
    - Limit unsuccessful login attempts.
    - Lock account after repeated failures.
    - Automatically unlock after a defined period.
    - Reset failure counter after a defined period.

## New-NISTGPO-AuditPolicy.ps1
- Configures the legacy audit policy GPO.

## New-NISTGPO-AdvancedAuditPolicy.ps1
- Configures auditpol.exe policy GPO.

## New-NistGPO-UserRightsAssignment.ps1
- Creates or updates a GPO to configure User Rights Assignment settings aligned with NIST requirements:
    - AC-2
    - AC-3
    - AC-6
    - IA-2

## New-NISTGPO-SecurityOptions.ps1
- Creates or updates a GPO to configure Security Options settings aligned with the following NIST requirements:
    - AC-17
    - IA-2
    - SC-7
    - SC-28

## New-NISTGPO-Firewall.ps1
- Creates or updates a GPO to configure Windows Firewall to be aligned with the following NIST requirements:
    - SC-7
    - SC-18

## New-NISTGPO-SystemHardening.ps1
- Creates or updates a GPO to configure System hardening Administrative Template settings aligned with the following NIST requirements.
    - CM-6
    - SC-4
    - SC-5
    - SC-7

## New-NISTGPO-NetworkHardening.ps1
- Creates or updates a GPO to configure Network hardening Administrative Template settings aligned with the follwing NIST requirements:
    - SC-7
    - SC-8

## New-NISTGPO-WindowsComponents.ps1
- Creates or updats a GPO to configure Windows Components hardening settings aligned with the following NIST requirements:
    - SC-7
    - SC-18
    - SI-3

## New-NISTGPO-AppLocker.ps1
- Creates or updats a GPO to configure AppLocker rules aligned with the following NIST requirements:
    - CM-7
    - SI-7
