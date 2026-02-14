#requires -Version 5.1
<#
.SYNOPSIS
    Pings an IP address, performs a traceroute, a reverse DNS lookup, and saves the results to a timestamped log file.

.DESCRIPTION
    This script prompts the user for an IP address, runs a ping test & a traceroute, performs a PTR (reverse DNS) lookup, and writes all results to a file selected by the user through a Save File diaglog. The output is appended to the file saved by the user.

.PARAMETER IPAddress
    The IP address to ping and resolve.

.EXAMPLE
    .\NetworkTroubleshooter.ps1 -IPAddress 8.8.8.8
    Runs the script against 8.8.8.8 and logs results to a chosen file.

.NOTES
    Author: SeekNotSought
    Version: 0.15
    Last Updated: 2026-02-13

    TODO:
        - Clean up output for Add-Content commands.
        - Improve error messaging.
        - Add logging level parameter (Verbos, Quiet)

.REQUIREMENTS
    PowerShell 5.1 (required for specific versions of the the Test-Connection commands)
    Windows OS
#>
param(
    [string]$IPAddress,
    [string]$OutputFile
)

# Pop up dialog box to save the results to if no output file is supplied in the parameter.
if (-not $OutputFile) {
    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Title = "Save your file"
    $dialog.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
    $dialog.DefaultExt = "txt"
    $dialog.FileName = "NetworkTroubleshooterResults_$(Get-Date -Format "yyyyMMdd_HHmmss").txt"

    # Show dialog
    #$OutputFile = $dialog.ShowDialog()

    if ($dialog.ShowDialog() -eq "OK") {
        $OutputFile = $dialog.FileName
        Write-Output "File will be saved to: $OutputFile"

        # Example: write something to the file
        "$(Get-Date): This is your script output" | Out-File $OutputFile -Encoding UTF8
    } else {
        Write-Output "$(Get-Date): Save canceled. Exiting" | Out-File $OutputFile -Append -Encoding UTF8 
        exit
    }
}
Write-Host "$(Get-Date): Results will be saved to: $OutputFile"

# Ask for IP to check if IP Address was not supplied as a parameter.
if (-not $IPAddress) {
    $InputPrompt = "$(Get-Date): Enter the IP you want to check"
    $IPAddress = Read-Host -Prompt $InputPrompt
    Add-Content -Path $OutputFile -Value $InputPrompt -Encoding UTF8
    Add-Content -Path $OutputFile -Value "$(Get-Date): The IP entered is: $IPAddress" -Encoding UTF8
    #Add-Content -Path $dialog.Filename -Value $IPAddress -Encoding UTF8
}

#Checking input to ensure the value is not null or empty
if ([string]::IsNullOrWhiteSpace($IPAddress)) {
    Write-Output "$(Get-Date): No IP entered. Exiting ..." | Out-String | Out-File $OutputFile -Append -Encoding UTF8
    exit 
}

# Ping the IP
$PingResults = Test-Connection "$IPAddress" -Count 4 -ErrorAction SilentlyContinue 

if (-not $PingResults) {
    Write-Output "$(Get-Date): The ping failed or the host is unreachable." | Out-String | Out-File $OutputFile -Append -Encoding UTF8
    exit
}
else {
    Add-Content -Path $dialog.Filename -Value "$(Get-Date): Below are the ping results for ${IPAddress}:" -Encoding UTF8
    $PingResults | Out-String | Out-File $OutputFile -Append -Encoding UTF8
    #Add-Content -Path $dialog.Filename -Value $PingResults -Encoding UTF8
}
# Traceroute the IP.
Add-Content -Path $dialog.Filename -Value "$(Get-Date): Below are the traceroute results:"
Test-NetConnection -ComputerName $IPAddress -TraceRoute -InformationLevel Detailed | Out-String | Out-File $OutputFile -Append -Encoding UTF8
# Look up the DNS record of the IP.
Add-Content -Path $dialog.Filename -Value "$(Get-Date): Below are the DNS record results:"
$DNS = Resolve-DnsName -Name $IPAddress -Type PTR -ErrorAction SilentlyContinue

if ($DNS) {
    "$(Get-Date): DNS Hostname: $($DNS.NameHost)" | Out-File $OutputFile -Append -Encoding UTF8
}
else {
    "$(Get-Date): DNS Hostname: No PTR record found" | Out-File $OutputFile -Append -Encoding UTF8
}

Write-Host "$(Get-Date): The script has completed."
Add-Content -Path $dialog.Filename -Value "$(Get-Date): The script has completed." -Encoding UTF8
Write-Host "$(Get-Date): Exiting ..."
Add-Content -Path $dialog.Filename -Value "$(Get-Date): Exiting ..." -Encoding UTF8
exit
