<#
.DESCRIPTION
        Add folder/files exclusions to Microsoft Defender
.AUTHOR
        Alex Panzetta
        alex.panzetta@aveva.com

.NOTES   
    Name       : Add-AVEVA-Folder-Exclusions-MSDefender.ps1
    Version    : 1.0.0
    DateCreated: 2024
#>
# Load the required assembly

Add-Type -AssemblyName System.Windows.Forms

$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
    Filter = "All files (*.txt)|*.txt"
    Title = 'Select text file containing AVEVA Folder Exclusions to open'
}

$result = $FileBrowser.ShowDialog()


# Check if the user clicked OK
if ($result -eq "OK") {
    # Get the selected file path
    $ExcludedFolders = Get-Content -Path $FileBrowser.FileName
    }
else {
    Write-Host "Cannot continue without a file path"
    Exit
    }

# Add each folder to Windows Defender exclusions
foreach ($Folder in $ExcludedFolders) {
    Write-Host "Adding folder exclusion: $Folder"
    Add-MpPreference -ExclusionPath $Folder
}

Write-Host "Folder exclusions added successfully."