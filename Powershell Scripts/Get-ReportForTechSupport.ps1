<#
.DESCRIPTION
        Gathers computer information to be shaed with Global Customer Support
.AUTHOR
        Alex Panzetta
        alex.panzetta@aveva.com

.NOTES   
    Name       : Get-ReportForTechSupport.ps1
    Version    : 1.0.0
    DateCreated: 2025
#>

# Function to get installed software by AVEVA
function Get-SchneiderSoftware {
    $searchVendors = "AVEVA", "Wonderware", "Schneider"

    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $softwareList = foreach ($path in $regPaths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object {
            $searchVendors | ForEach-Object { $_ -and $_ -ne "" -and $_ -match $_.Publisher }
        }
    }

    return $softwareList | Sort-Object DisplayName
}

function Get-SubnetMask {
        param ($prefix)
        $binaryMask = ("1" * $prefix).PadRight(32, "0")
        $subnet = ($binaryMask -split '(.{8})' | Where-Object { $_ }) |
                  ForEach-Object { [Convert]::ToInt32($_, 2) }
        return ($subnet -join '.')
    }

# Prompt user for output HTML file path
Add-Type -AssemblyName System.Windows.Forms

$dialog = New-Object System.Windows.Forms.SaveFileDialog
$dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
$dialog.Filter = "HTML files (*.html)|*.html"
$dialog.Title = "Save System Report As"
$dialog.FileName = $env:COMPUTERNAME + "_SystemReport.html"

$savePath = $null
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $savePath = $dialog.FileName
} else {
    Write-Host "❌ Save operation cancelled. Exiting script."
    exit
}

# Initialize a string builder for the report
$report = @()

# --- SYSTEM INFO ---
$sysInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$hotfixes = Get-HotFix | Sort-Object -Property InstalledOn -Descending

$report += "<h2>System Information</h2>"
$report += "<ul>"
$report += "<li><strong>Computer Name:</strong> $($env:COMPUTERNAME)</li>"
$report += "<li><strong>OS:</strong> $($sysInfo.Caption) $($sysInfo.Version)</li>"
$report += "<li><strong>Build:</strong> $($sysInfo.BuildNumber)</li>"
$report += "<li><strong>Install Date:</strong> $($sysInfo.InstallDate)</li>"
$report += "</ul>"

$report += "<h3>Installed Hotfixes</h3><ul>"
foreach ($fix in $hotfixes) {
    $report += "<li>$($fix.HotFixID) - Installed on $($fix.InstalledOn)</li>"
}
$report += "</ul>"

# --- NETWORK INFO ---
$report += "<h2>Network Configuration</h2>"
$adapters = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -ne $null }

foreach ($adapter in $adapters) {
    $subnet = Get-SubnetMask -prefix $adapter.IPv4Address.PrefixLength
    #("1" * $adapter.IPv4Address.PrefixLength).PadRight(32, "0") -split '(.{8})' | Where-Object { $_ } | ForEach-Object { [Convert]::ToInt32($_, 2) } -join '.'
    $dns = $adapter.DnsServer.ServerAddresses -join ', '

    $report += "<h4>$($adapter.InterfaceAlias)</h4><ul>"
    $report += "<li><strong>Interface Index:</strong> $($adapter.InterfaceIndex)</li>"
    $report += "<li><strong>IP Address:</strong> $($adapter.IPv4Address.IPAddress)</li>"
    $report += "<li><strong>Subnet Mask:</strong> $subnet</li>"
    $report += "<li><strong>Gateway:</strong> $($adapter.IPv4DefaultGateway.NextHop)</li>"
    $report += "<li><strong>DNS Servers:</strong> $dns</li>"
    $report += "</ul>"
}

# --- SOFTWARE INVENTORY ---
$report += "<h2>AVEVA / Wonderware / Schneider Electric Software</h2>"

$schneiderApps = Get-SchneiderSoftware
if ($schneiderApps.Count -eq 0) {
    $report += "<p>No AVEVA, Wonderware or Schneider Electric software was found on this system.</p>"
} else {
    $report += "<table border='1'><tr><th>Name</th><th>Version</th><th>Install Date</th><th>Installed By</th><th>Publisher</th></tr>"
    foreach ($app in $schneiderApps) {
        $installDate = if ($app.InstallDate) {
            # Convert from yyyymmdd to a readable format
            [datetime]::ParseExact($app.InstallDate, "yyyyMMdd", $null).ToShortDateString()
        } else {
            "Unknown"
        }

    $installedBy = "Unknown"
    if ($app.InstallSource -and (Test-Path $app.InstallSource) -and ($app.InstallSource -match '^[A-Z]:\\')) {
        try {
            $owner = (Get-Acl -Path $app.InstallSource -ErrorAction Stop).Owner
            if ($owner) {
                $installedBy = $owner
            }
        } catch {
            # silently skip errors
        }
    }


        $report += "<tr><td>$($app.DisplayName)</td><td>$($app.DisplayVersion)</td><td>$installDate</td><td>$installedBy</td><td>$($app.Publisher)</td></tr>"
    }
    $report += "</table>"
}

# --- EVENT LOGS ---
function Get-EventLogHtml {
    param ($logName)

    $events = Get-EventLog -LogName $logName -EntryType Error, Warning -Newest 30 |
        Select-Object TimeGenerated, EntryType, EventID, Source, Message

    $html = "<h2>Event Log: $logName (Last 30 Errors and Warnings only)</h2><table border='1'><tr><th>Time</th><th>Type</th><th>ID</th><th>Source</th><th>Message</th></tr>"
    foreach ($e in $events) {
        $msg = $e.Message -replace '\r|\n', ' '
        $html += "<tr><td>$($e.TimeGenerated)</td><td>$($e.EntryType)</td><td>$($e.EventID)</td><td>$($e.Source)</td><td>$msg</td></tr>"
    }
    $html += "</table>"
    return $html
}

$report += Get-EventLogHtml -logName "System"
$report += Get-EventLogHtml -logName "Application"

# Convert to full HTML and save
$htmlHeader = "<html><head><title>" + $env:COMPUTERNAME + " System Report</title><style>body{font-family:sans-serif}table{border-collapse:collapse;width:100%}td,th{padding:6px;border:1px solid #ccc}</style></head><body>"
$htmlFooter = "</body></html>"
$fullHtml = $htmlHeader + ($report -join "`n") + $htmlFooter

# Save to HTML
Set-Content -Path $savePath -Value $fullHtml -Encoding UTF8

Write-Host "`n✅ Report saved to: $savePath"
