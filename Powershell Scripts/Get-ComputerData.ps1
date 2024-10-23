<#
.SYNOPSIS
    This script collects local logs and configurations that will eb saved in a central repository

.NOTES   
    Name       : Get-ComputerData.ps1
    Author     : Alex Panzetta
    Email      : alex.panzetta@aveva.com
    Version    : 1.0
    LastModified: August 2023
#>

# Output save paths
$CentralRepository = "\\YourServerName\AvevaSupportUpload" # change this to match your UNC path
$CurrPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SaveDataPath = $CurrPath + "\Data\" + $env:COMPUTERNAME
$SysInfoSavePath = $SaveDataPath + "\SystemInfo\"
$EvtVwrSavePath = $SaveDataPath + "\EvtVwrLogs\"
$IOConfigSavePath = $SaveDataPath + "\IO-Configurations\"
$SMCSavePath = $SaveDataPath + "\SMC-Log\"
$LicensingSavePath = $SaveDataPath + "\Licensing\"
$PlatformMappingSavePath = $SaveDataPath + "\PlatformMapping\"
$GlobalDataCache = $SaveDataPath + "\PlatformMapping\GlobalDataCache\"
$GalaxyData = $SaveDataPath + "\PlatformMapping\GalaxyData\"
$SQLLogSavePath = $SaveDataPath + "\SQL-Log\"
$ASBCertsPath = $SaveDataPath + "\ASB-Certs\"




# Remove old data
if (Test-Path $SaveDataPath ) {
    Remove-Item $SaveDataPath -Recurse
  }
If(!(Test-Path -PathType container $SysInfoSavePath))
{
      New-Item -ItemType Directory -Path $SysInfoSavePath
}
If(!(Test-Path -PathType container $EvtVwrSavePath))
{
      New-Item -ItemType Directory -Path $EvtVwrSavePath
}



# Get System Information
Write-Host -ForegroundColor Cyan "Getting System Info"
systeminfo.exe /S $env:COMPUTERNAME /FO LIST | Where-Object {$_.trim() -ne ""} | Out-File -FilePath $SysInfoSavePath$env:COMPUTERNAME.txt


# Get Event Viewer Logs
Write-Host -ForegroundColor Cyan "Getting Application log"
$LogOut = $EvtVwrSavePath + $env:computername + "_Application_log.evtx"

if (Test-Path $LogOut) {
    Remove-Item $LogOut
  }
wevtutil.exe epl Application $LogOut /ow:true

Write-Host -ForegroundColor Cyan "Getting System log"
$LogOut = $EvtVwrSavePath + $env:computername + "_System_log.evtx"
if (Test-Path $LogOut) {
    Remove-Item $LogOut
  }
wevtutil.exe epl System $LogOut /ow:true

Write-Host -ForegroundColor Cyan "Getting Security log"
$LogOut = $EvtVwrSavePath + $env:computername + "_Security_log.evtx"
if (Test-Path $LogOut) {
    Remove-Item $LogOut
  }
wevtutil.exe epl Security $LogOut /ow:true

# Get IO configurations
If(Test-Path -PathType container "C:\ProgramData\Wonderware\OI-Server")
{
    Write-Host -ForegroundColor Cyan "Copying OI-Server configuration"
      If(!(Test-Path -PathType container $IOConfigSavePath))
        {
              New-Item -ItemType Directory -Path $IOConfigSavePath
        }
      Get-ChildItem C:\ProgramData\Wonderware\OI-Server -Filter *.aacfg -WarningAction Ignore -ErrorAction Ignore -Recurse | Copy-Item -Destination $IOConfigSavePath -Force -PassThru
}
If(Test-Path -PathType container "C:\ProgramData\Wonderware\DAServer")
{
    Write-Host -ForegroundColor Cyan "Copying DAServer configuration"
      If(!(Test-Path -PathType container $IOConfigSavePath))
        {
              New-Item -ItemType Directory -Path $IOConfigSavePath
        }
      Get-ChildItem C:\ProgramData\Wonderware\DAServer -Filter *.aacfg  -WarningAction Ignore -ErrorAction Ignore -Recurse | Copy-Item -Destination $IOConfigSavePath -Force -PassThru
}


# Get licenses and logs
If(Test-Path -PathType container "C:\Program Files (x86)\Common Files\ArchestrA\License"){
    Write-Host -ForegroundColor Cyan "Copying license info"
    If(!(Test-Path -PathType container $LicensingSavePath))
        {
          New-Item -ItemType Directory -Path $LicensingSavePath
        }
    Get-ChildItem "C:\Program Files (x86)\Common Files\ArchestrA\License" -Filter *.lic -WarningAction Ignore -ErrorAction Ignore -Recurse | Copy-Item -Destination $LicensingSavePath -Force -PassThru
}
If(Test-Path -PathType container "C:\ProgramData\AVEVA\Licensing\License Server"){
    Write-Host -ForegroundColor Cyan "Copying license server logs"
    If(!(Test-Path -PathType container $LicensingSavePath))
        {
          New-Item -ItemType Directory -Path $LicensingSavePath
        }
    Get-ChildItem "C:\ProgramData\AVEVA\Licensing\License Server" -Filter *.log -WarningAction Ignore -ErrorAction Ignore -Recurse | Copy-Item -Destination $LicensingSavePath -Force -PassThru
}
If(Test-Path -PathType container "C:\ProgramData\Schneider Electric\Licensing\License Server"){
    Write-Host -ForegroundColor Cyan "Copying license server logs"
    If(!(Test-Path -PathType container $LicensingSavePath))
        {
          New-Item -ItemType Directory -Path $LicensingSavePath
        }
    Get-ChildItem "C:\ProgramData\Schneider Electric\Licensing\License Server" -Filter *.log -WarningAction Ignore -ErrorAction Ignore -Recurse | Copy-Item -Destination $LicensingSavePath -Force -PassThru
}
 
 #Get license features
 Write-Host -ForegroundColor Cyan "Getting License Server loaded features"
 if (Test-Path $LicensingSavePath\$env:COMPUTERNAME-LicenseFeatures.txt ) {
    Remove-Item $LicensingSavePath\$env:COMPUTERNAME-LicenseFeatures.txt 
  }
"FeatureName,Version,Count,StartDate,ExpiryDate"| Out-File -FilePath $LicensingSavePath\$env:COMPUTERNAME-LicenseFeatures.txt -Append
$LicenseServer = [xml](New-Object System.Net.WebClient).downloadstring('http://' + $env:COMPUTERNAME + ':55555/fne/xml/features')
$Features = $LicenseServer.feature_usage.features.feature
ForEach ($Feature in $Features) 
    {
        $Fname = $Feature.name
        $FCount = $Feature.count
        $FStarts =$Feature.starts
        $FExpires =  $Feature.expiry
        $FVersion = $Feature.version
        $Fname + "," + $FVersion + "," + $FCount  + "," + $FStarts + "," + $FExpires| Out-File -FilePath $LicensingSavePath\$env:COMPUTERNAME-LicenseFeatures.txt -Append
    }

# Get Platform Mapping
If(Test-Path -PathType container "C:\Program Files (x86)\ArchestrA\Framework\Bin\GlobalDataCache"){
    Write-Host -ForegroundColor Cyan "Copying Platform Mapping GlobalDataCache"
    If(!(Test-Path -PathType container $GlobalDataCache))
        {
              New-Item -ItemType Directory -Path $GlobalDataCache
        }
    Get-ChildItem "C:\Program Files (x86)\ArchestrA\Framework\Bin\GlobalDataCache" -Filter PlatformMapping.xml -WarningAction Ignore -ErrorAction Ignore -Recurse | Copy-Item -Destination $GlobalDataCache -Force -PassThru
}
If(Test-Path -PathType container "C:\Program Files (x86)\ArchestrA\Framework\Bin\GalaxyData"){
    Write-Host -ForegroundColor Cyan "Copying Platform Mapping GalaxyData"
    If(!(Test-Path -PathType container $GalaxyData))
        {
              New-Item -ItemType Directory -Path $GalaxyData
        }
    Get-ChildItem "C:\Program Files (x86)\ArchestrA\Framework\Bin\GalaxyData" -Filter PlatformMapping.xml -WarningAction Ignore -ErrorAction Ignore -Recurse | Copy-Item -Destination $GalaxyData -Force -PassThru
}
If(Test-Path "HKLM:\SOFTWARE\WOW6432Node\ArchestrA\Framework\Platform\PlatformNodes\"){
    Write-Host -ForegroundColor Cyan "Copying Platform Mapping Registry"
    If(!(Test-Path -PathType container $PlatformMappingSavePath))
        {
              New-Item -ItemType Directory -Path $PlatformMappingSavePath
        }
    $RegFileOut = $PlatformMappingSavePath + $env:computername + "_PlatformFromRegistry.txt"
    Get-ChildItem -Path 'HKLM:\SOFTWARE\WOW6432Node\ArchestrA\Framework\Platform\PlatformNodes\' -ErrorAction SilentlyContinue| Out-File $RegFileOut
}
 

# Get SMC Logs
Write-Host -ForegroundColor Cyan "Exporting SMC Logs"
If(!(Test-Path -PathType container $SMCSavePath))
    {
        New-Item -ItemType Directory -Path $SMCSavePath
    }
.\LogReaderApp.exe days:7 logflags:error,warning output:$env:COMPUTERNAME-SMC-Export.csv
Copy-Item -Path $env:COMPUTERNAME-SMC-Export.csv -Destination $SMCSavePath -WarningAction Ignore -ErrorAction Ignore



# Get SQL Logs
Write-Host -ForegroundColor Cyan "Exporting SQL Logs"
If(!(Test-Path -PathType container $SQLLogSavePath))
    {
        New-Item -ItemType Directory -Path $SQLLogSavePath
    }
$SQLLogLocation = Invoke-Sqlcmd -Query "xp_readerrorlog 0, 1, N'Logging SQL Server messages in file'" -Database "master" | Select-Object -ExpandProperty Text
$SQLLogFile = $SQLLogLocation.Replace("Logging SQL Server messages in file ","").Replace("'","").Replace("ERRORLOG.","ERRORLOG")
Copy-Item -Path $SQLLogFile -Destination $SQLLogSavePath -WarningAction Ignore -ErrorAction Ignore


# Get ASB Certificates details
If(!(Test-Path -PathType container $ASBCertsPath))
        {
              New-Item -ItemType Directory -Path $ASBCertsPath
        }
$ASBCertsFilePath = $ASBCertsPath + "ASBCertificates.txt"
dir -r Cert:\LocalMachine\ | where { $_.Issuer -like "*ASB*" }  | Select-Object FriendlyName, NotAfter, Issuer | Out-File $ASBCertsFilePath

# Save all
Write-Host -ForegroundColor Cyan "Saving files"

# Remove old ZIP file 
$ZipFile = $CurrPath + "\" + $env:COMPUTERNAME + ".zip"
if (Test-Path $ZipFile) {
    Remove-Item $ZipFile
  }

# Create new ZIP file 
Compress-Archive -Path $CurrPath"\Data" -DestinationPath $ZipFile -Update

# Upload ZIP file to $CentralRepository
Move-Item -Path $ZipFile -Destination $CentralRepository -Force -PassThru

Write-Host -ForegroundColor Green "All data have been collected and saved to" $CentralRepository 