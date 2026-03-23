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