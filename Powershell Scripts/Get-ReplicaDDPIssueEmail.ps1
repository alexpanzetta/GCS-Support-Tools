<#
.DESCRIPTION
        Checks if there are replica requests that may cause DDP issues in Insight
        If there are data that are 50+ days old, you'll need to update the ReplicationSyncRequest table 
        and stagger the data in batches of 30 items every 15 minutes. 
        
        E.g.:
            UPDATE ReplicationSyncRequest
            SET EarliestExecutionDateTimeUTC = '2025-04-02 14:00'
            WHERE ModStartDateTimeUTC <= '2025-03-01'
            AND ExecuteState = 0;


            UPDATE ReplicationSyncRequest
            SET EarliestExecutionDateTimeUTC = '2025-04-02 14:15'
            WHERE ModStartDateTimeUTC <= '2025-03-02'
            AND ExecuteState = 0;


            ... etc.

.AUTHOR
        Alex Panzetta
        alex.panzetta@aveva.com

.NOTES   
    Name       : Get-ReplicaDDPIssueEmail.ps1
    Version    : 1.0.0
    DateCreated: 2025
#>


# Connect to SQL and run query
$query = @"
SELECT *
FROM ReplicationSyncRequestInfo
WHERE ModStartDateTimeUTC <= DATEADD(DAY, -50, GETDATE())
"@

$result = Invoke-Sqlcmd -ServerInstance "HISTORIANSERVER" -Database "Runtime" -Query $query

if ($result) {
    
    Send-MailMessage -From "you@example.com" -To "you@example.com" `
        -Subject "Historian potential DDP Issue" `
        -Body "There are replication entries older than 50 days. You'll need to update the ReplicationSyncRequest table and stagger the data in batches of 30 items every 15 minutes. 
        E.g.:
            UPDATE ReplicationSyncRequest
            SET EarliestExecutionDateTimeUTC = '2025-04-02 14:00'
            WHERE ModStartDateTimeUTC <= '2025-03-01'
            AND ExecuteState = 0;


            UPDATE ReplicationSyncRequest
            SET EarliestExecutionDateTimeUTC = '2025-04-02 14:15'
            WHERE ModStartDateTimeUTC <= '2025-03-02'
            AND ExecuteState = 0;


            ... etc." `
        -SmtpServer "smtp.yourserver.com"
}
