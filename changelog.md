# 0.19
- Renamed the `CompareRecycleBin.ps1` to `GetRecycleBin.ps1`.
- Changed the script contents in `GetRecycleBin.ps1` into a function.
- Updated the headers in `GetRecycleBin.ps1`.
- Started to work on `CompareAllUsersRecycleBin.ps1`

# 0.18
- Added the ability to get all of the files in the current user's recycling bin in `CompareRecycleBin.ps1`.

# 0.17
- Created a header for `CompareRecycleBin.ps1`

# 0.16
- Created the folder `RecycleBinCompare`
- Created the file `CompareAllUsersRecycleBin.ps1`
    - Will have script to look in every user's recycle bin and see if the files in the recycling bin still exists in the original location.
- Created the file `CompareRecycleBin.ps1`
    - Will have the script look in the current user's recycle bin and see if the files in the recycling bin still exists in the original location.

# 0.15
- Added headers for script.
- Added parameters for IP Address and Output file.
- Added logic that if no parameters are supplied to prompt the user for the necessary information.

# 0.14
- Added lookup of DNS record for supplied IP.
- Added a couple lines indicating the script has completed to both the host and in the logs.

# 0.13
- Added timestamps to each entry in the log file.
- Change the default filename to "NetworkTroubleShooter" with a timestamp.
- Fixed output to the log file for the ping command.

# 0.12
- Fixed script to add the IP to the saved file. Before it caused the script to exit prematurely.

# 0.11
- Started working on appending results to the text file that was saved via the dialog box.

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