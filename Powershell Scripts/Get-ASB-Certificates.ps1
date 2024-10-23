<#
.SYNOPSIS
    This script Will retrieve info from ArchestrA Service Bus (a.k.a ASB) certificates use by 
    Platform Common Services (a.k.a PCS) and save the resuls to a text file.

.NOTES   
    Name       : Get-ASB-Certificates.ps1
    Author     : Alex Panzetta
    Email      : alex.panzetta@aveva.com
    Version    : 1.0
    LastModified: October 2024
#>

# Load the required assembly
Add-Type -AssemblyName System.Windows.Forms

$DesktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)


# Create a SaveFileDialog object
$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog

# Set properties for the dialog
$saveFileDialog.Filter = "All files (*.txt)|*.txt"
$saveFileDialog.Title = "Save As"
$saveFileDialog.InitialDirectory = $DesktopPath  
$saveFileDialog.FileName = $env:COMPUTERNAME + "_ASBCertificates.txt"

# Show the dialog
$result = $saveFileDialog.ShowDialog()

# Check if the user clicked OK
if ($result -eq "OK") {
    # Get the selected file path
    $outputFilePath = $saveFileDialog.FileName
    }
else {
    Write-Host "Cannot continue without a file path"
    Exit
    }
