#requires -Version 5.1
# Placeholder for Network Troubleshooter script.

# Below are notes for the plan and flow of the script.

# Pop up dialog box to save the results to.

# Ask for IP to check & output the results.
$IP_ToCheck = Read-Host -Prompt "Enter the IP you want to check"
# Ping the IP.
Test-Connection "$IP_ToCheck" -Count 4 
# Traceroute the IP.
Test-NetConnection -ComputerName $IP_ToCheck -TraceRoute -InformationLevel Detailed
# Look up the DNS record of the IP.