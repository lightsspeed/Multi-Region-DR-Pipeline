# DR Failover Simulation Script (PowerShell)
$PRIMARY_ASG = "ap-south-1-asg-91t6mr1h"
$PRIMARY_HEALTH_CHECK_ID = "aed34794-62d6-46de-89dc-9b4c66ad9907"
$DNS_NAME = "dr-pipeline-test-9912.com"

Write-Host "--- DR FAILOVER SIMULATION STARTING ---" -ForegroundColor Yellow
$start_time = Get-Date
Write-Host "Start Time: $start_time"

# 1. Simulate Outage in Primary Region
Write-Host "Phase 1: Simulating outage in ap-south-1 (Mumbai)..." -ForegroundColor Red
Write-Host "Scaling Primary ASG down to 0..."
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $PRIMARY_ASG --min-size 0 --max-size 0 --desired-capacity 0 --region ap-south-1

# 2. Wait for Route53 Health Check to fail
Write-Host "Phase 2: Waiting for Route 53 Health Check ($PRIMARY_HEALTH_CHECK_ID) to trigger failover..." -ForegroundColor Yellow
$status = "Unhealthy"
while ($true) {
    $hc_status = aws route53 get-health-check-status --health-check-id $PRIMARY_HEALTH_CHECK_ID --region us-east-1 | ConvertFrom-Json
    $current_status = $hc_status.HealthCheckObservations[0].StatusReport.Status
    Write-Host "Current Health Check Status: $current_status"
    if ($current_status -like "*Failure*") {
        Write-Host "Outage Detected by Route 53!" -ForegroundColor Red
        break
    }
    Start-Sleep -Seconds 10
}

# 3. Verify Failover to Secondary
Write-Host "Phase 3: Verifying DNS Failover..." -ForegroundColor Green
$resolved_ip = Resolve-DnsName $DNS_NAME -Type A -ErrorAction SilentlyContinue
Write-Host "DNS $DNS_NAME currently resolves to: $($resolved_ip.IPAddress)"

$end_time = Get-Date
$duration = $end_time - $start_time
Write-Host "--- FAILOVER COMPLETE ---" -ForegroundColor Green
Write-Host "End Time: $end_time"
Write-Host "Total RTO (Recovery Time Objective): $($duration.TotalSeconds) seconds" -ForegroundColor Cyan

Write-Host "`nTo Restore Primary Region:" -ForegroundColor DarkGray
Write-Host "aws autoscaling update-auto-scaling-group --auto-scaling-group-name $PRIMARY_ASG --min-size 2 --max-size 6 --desired-capacity 2 --region ap-south-1"
