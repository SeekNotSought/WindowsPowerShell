#requires -Version 5.1
# Placeholder for Network Troubleshooter script.

# Below are notes for the plan and flow of the script.

# Pop up dialog box to save the results to.
Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.SaveFileDialog
$dialog.Title = "Save your file"
$dialog.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
$dialog.DefaultExt = "txt"
$dialog.FileName = "results.txt"

# Show dialog
$result = $dialog.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $savePath = $dialog.FileName
    Write-Output "File will be saved to: $savePath"

    # Example: write something to the file
    "This is your script output" | Out-File $savePath -Encoding UTF8
} else {
    Write-Output "Save canceled." | Out-File $savePath -Append -Encoding UTF8 
}

# Ask for IP to check & output the results.
$IP_ToCheck = Read-Host -Prompt "Enter the IP you want to check" | Out-String | Out-File $savePath -Append -Encoding UTF8 
#Checking input to ensure the value is not null or empty
if ([string]::IsNullOrWhiteSpace($IP_ToCheck)) {
    Write-Output "No IP entered. Exiting ..." | Out-String | Out-File $savePath -Append -Encoding UTF8
    exit 
}
# Ping the IP
$results = Test-Connection "$IP_ToCheck" -Count 4 -ErrorAction SilentlyContinue

if (-not $results) {
    Write-Output "The ping failed or the host is unreachable." | Out-String | Out-File $savePath -Append -Encoding UTF8
    exit
}

# Traceroute the IP.
Test-NetConnection -ComputerName $IP_ToCheck -TraceRoute -InformationLevel Detailed | Out-String | Out-File $savePath -Append -Encoding UTF8
# Look up the DNS record of the IP.