# 0.10
- Changed `if ([string])::ISNullOrWhiteSpace($IP_ToCheck)` on line 13 to `if ([string]::IsNullOrWhiteSpace($IP_ToCheck))` to resolve a detected problem.

# 0.09
- Continued work on save dialog box in `NetworkTroubleshooter.ps1`.
- Added a check on the input for the IP address.
- If the ping fails or the host is unreachable, provides a message to the host.

# 0.06
- Begain work on save dialog box in `NetworkTroubleshooter.ps1`.

# 0.05
- Added a requirement for PowerShell version 5.1 to `NetworkTroubleshooter.ps1`.
- Began working on the PowerShell equivalent of tracert.

# 0.04
- Began working on ping for `NetworkTroubleshooter.ps1`.
- Able to take input and perform a ping.
    - Will need to check for PowerShell version as the Test-Connection command is very different from PowerShell version 5.1 compared to 7.x.

# 0.03
- Added notes to the `NetworkTroubleshooter.ps1` to create the plan and flow of the script.

# 0.02 
- Created `changelog.md` file.
- Decided on first script's purpose, troubleshooting a network issue.
    - Ideally will output the most likely cause for the network issue. 

# 0.01 Initial Commit
- Created the `ReadMe.md` file.