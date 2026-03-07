<#
.SYNOPSIS
Installs programs from a supplied list of installers.

.DESCRIPTION
Detects installer type (.msi or .exe) and installs accordingly.
Supports silent install arguments and basic logging.

.NOTES
Author: YourName
Use case: Endpoint automation / Terraform provisioner / imaging
#>

# -------------------------
# Installer List
# -------------------------

$Installers = @(
    @{
        Name = "7zip"
        Path = "C:\Installers\7z2301-x64.msi"
        Args = "/qn /norestart"
    },
    @{
        Name = "Google Chrome"
        Path = "C:\Installers\ChromeSetup.exe"
        Args = "/silent /install"
    },
    @{
        Name = "VSCode"
        Path = "C:\Installers\VSCodeSetup.exe"
        Args = "/verysilent /mergetasks=!runcode"
    }
)

# -------------------------
# Logging
# -------------------------

$LogFile = "C:\Installers\install_log.txt"

function Write-Log {
    param(
        [string]$Message
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $Message" | Out-File -FilePath $LogFile -Append
}

# -------------------------
# Install Function
# -------------------------

function Install-Program {

    param(
        [string]$Name,
        [string]$Path,
        [string]$Args
    )

    if (!(Test-Path $Path)) {
        Write-Log "$Name installer not found: $Path"
        return
    }

    $Extension = [System.IO.Path]::GetExtension($Path)

    Write-Log "Installing $Name"

    switch ($Extension) {

        ".msi" {

            $arguments = "/i `"$Path`" $Args"

            Start-Process `
                -FilePath "msiexec.exe" `
                -ArgumentList $arguments `
                -Wait `
                -NoNewWindow
        }

        ".exe" {

            Start-Process `
                -FilePath $Path `
                -ArgumentList $Args `
                -Wait `
                -NoNewWindow
        }

        default {

            Write-Log "Unsupported installer type: $Extension"
            return
        }
    }

    Write-Log "$Name installation completed"
}

# -------------------------
# Main Loop
# -------------------------

foreach ($App in $Installers) {

    Install-Program `
        -Name $App.Name `
        -Path $App.Path `
        -Args $App.Args
}

Write-Log "All installations finished."