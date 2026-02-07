#requires -Version 5.1
# Placeholder for Network Troubleshooter script.

# Below are notes for the plan and flow of the script.

# Pop up dialog box to save the results to.
Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.SaveFileDialog
$dialog.Title = "Save your file"
$dialog.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
$dialog.DefaultExt = "txt"
$dialog.FileName = "output.txt"

# Show dialog
$result = $dialog.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $savePath = $dialog.FileName
    Write-Host "File will be saved to: $savePath"

    # Example: write something to the file
    "Hello world!" | Out-File $savePath
} else {
    Write-Host "Save canceled."
}

# Ask for IP to check & output the results.
$IP_ToCheck = Read-Host -Prompt "Enter the IP you want to check"
# Ping the IP.
Test-Connection "$IP_ToCheck" -Count 4 
# Traceroute the IP.
Test-NetConnection -ComputerName $IP_ToCheck -TraceRoute -InformationLevel Detailed
# Look up the DNS record of the IP.