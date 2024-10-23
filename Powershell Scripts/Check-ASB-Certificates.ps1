<#
.SYNOPSIS
    This script Will check ArchestrA Service Bus (a.k.a ASB) certificates expiration

.NOTES   
    Name       : Check-ASB-Certificates.ps1
    Author     : Alex Panzetta
    Email      : alex.panzetta@aveva.com
    Version    : 1.0
    LastModified: October 2024
#>

Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Issuer -like "*ASB*" }  |
  ForEach-Object {
    $cert = $_
    $CertificateName = $($cert.FriendlyName)
    $CertificateExpirationDate = $($cert.NotAfter)
    $TodaysDate = Get-Date -Format "M/d/yyyy hh:mm:ss tt"
    $CertTimeDiff = New-TimeSpan -Start $TodaysDate -End $CertificateExpirationDate
    
    if ($CertTimeDiff -lt 1) {
        Write-Host -ForegroundColor Red "[" $CertificateName"] expired on " $CertificateExpirationDate 
        }
    else {
        Write-Host -ForegroundColor Green "[" $CertificateName"] is valid and will expire in " $CertTimeDiff " days" 
        }
  }