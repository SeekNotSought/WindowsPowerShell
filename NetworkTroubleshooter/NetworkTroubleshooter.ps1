#requires -Version 5.1
# Placeholder for Network Troubleshooter script.

# Below are notes for the plan and flow of the script.

# Pop up dialog box to save the results to.
Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.SaveFileDialog
$dialog.Title = "Save your file"
$dialog.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
$dialog.DefaultExt = "txt"
$dialog.FileName = "NetworkTroubleshooterResults_$(Get-Date -Format "yyyyMMdd_HHmmss").txt"

# Show dialog
$result = $dialog.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $savePath = $dialog.FileName
    Write-Output "File will be saved to: $savePath"

    # Example: write something to the file
    "$(Get-Date): This is your script output" | Out-File $savePath -Encoding UTF8
} else {
    Write-Output "$(Get-Date): Save canceled." | Out-File $savePath -Append -Encoding UTF8 
}

# Ask for IP to check & output the results.
$InputPrompt = "$(Get-Date): Enter the IP you want to check"
$IP_ToCheck = Read-Host -Prompt $InputPrompt
Add-Content -Path $dialog.Filename -Value $InputPrompt -Encoding UTF8
Add-Content -Path $dialog.Filename -Value "$(Get-Date): The IP entered is: $IP_ToCheck" -Encoding UTF8
#Add-Content -Path $dialog.Filename -Value $IP_ToCheck -Encoding UTF8
#Checking input to ensure the value is not null or empty
if ([string]::IsNullOrWhiteSpace($IP_ToCheck)) {
    Write-Output "$(Get-Date): No IP entered. Exiting ..." | Out-String | Out-File $savePath -Append -Encoding UTF8
    exit 
}
# Ping the IP
$PingResults = Test-Connection "$IP_ToCheck" -Count 4 -ErrorAction SilentlyContinue 

if (-not $PingResults) {
    Write-Output "$(Get-Date): The ping failed or the host is unreachable." | Out-String | Out-File $savePath -Append -Encoding UTF8
    exit
}
else {
    Add-Content -Path $dialog.Filename -Value "$(Get-Date): Below are the ping results:" -Encoding UTF8
    $PingResults | Out-String | Out-File $savePath -Append -Encoding UTF8
    #Add-Content -Path $dialog.Filename -Value $PingResults -Encoding UTF8
}
# Traceroute the IP.
Add-Content -Path $dialog.Filename -Value "$(Get-Date): Below are the traceroute results:"
Test-NetConnection -ComputerName $IP_ToCheck -TraceRoute -InformationLevel Detailed | Out-String | Out-File $savePath -Append -Encoding UTF8
# Look up the DNS record of the IP.
Add-Content -Path $dialog.Filename -Value "$(Get-Date): Below are the DNS record results:"
$DNS = Resolve-DnsName -Name $IP_ToCheck -Type PTR -ErrorAction SilentlyContinue

if ($DNS) {
    "$(Get-Date): DNS Hostname: $($DNS.NameHost)" | Out-File $savePath -Append -Encoding UTF8
}
else {
    "$(Get-Date): DNS Hostname: No PTR record found" | Out-File $savePath -Append -Encoding UTF8
}

Write-Host "$(Get-Date): The script has completed."
Add-Content -Path $dialog.Filename -Value "$(Get-Date): The script has completed." -Encoding UTF8
Write-Host "$(Get-Date): Exiting ..."
Add-Content -Path $dialog.Filename -Value "$(Get-Date): Exiting ..." -Encoding UTF8
exit
