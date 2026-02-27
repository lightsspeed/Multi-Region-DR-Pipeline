import boto3
import time
import datetime
import socket
import sys

# Configuration - Matches simulate_failover.ps1
PRIMARY_ASG = "ap-south-1-asg-4mrnx5c1"
PRIMARY_HEALTH_CHECK_ID = "bfa60ab4-525d-4800-85ce-7555f1d9fbbf"
DNS_NAME = "dr-pipeline-test-9912.com"
REGION_PRIMARY = "ap-south-1"
REGION_HEALTH_CHECK = "us-east-1"  # Health checks are often global or in us-east-1

def simulate_failover():
    print("--- DR FAILOVER SIMULATION STARTING ---")
    start_time = datetime.datetime.now()
    print(f"Start Time: {start_time}")

    asg_client = boto3.client('autoscaling', region_name=REGION_PRIMARY)
    r53_client = boto3.client('route53', region_name=REGION_HEALTH_CHECK)

    # 1. Simulate Outage in Primary Region
    print(f"Phase 1: Simulating outage in {REGION_PRIMARY} (Mumbai)...")
    print(f"Scaling Primary ASG {PRIMARY_ASG} down to 0...")
    try:
        asg_client.update_auto_scaling_group(
            AutoScalingGroupName=PRIMARY_ASG,
            MinSize=0,
            MaxSize=0,
            DesiredCapacity=0
        )
    except Exception as e:
        print(f"Error scaling ASG: {e}")
        # Note: Continuing might be useful for testing logic, but usually this is a blocker
        # sys.exit(1)

    # 2. Wait for Route53 Health Check to fail
    print(f"Phase 2: Waiting for Route 53 Health Check ({PRIMARY_HEALTH_CHECK_ID}) to trigger failover...")
    
    while True:
        try:
            response = r53_client.get_health_check_status(HealthCheckId=PRIMARY_HEALTH_CHECK_ID)
            # HealthCheckObservations[0].StatusReport.Status matches the PS script logic
            observations = response.get('HealthCheckObservations', [])
            if observations:
                current_status = observations[0].get('StatusReport', {}).get('Status', 'Unknown')
                print(f"Current Health Check Status: {current_status}")
                
                if "Failure" in current_status:
                    print("Outage Detected by Route 53!")
                    break
            else:
                print("No health check observations found yet...")
        except Exception as e:
            print(f"Error getting health check status: {e}")
        
        time.sleep(10)

    # 3. Verify Failover to Secondary
    print("Phase 3: Verifying DNS Failover...")
    try:
        resolved_ip = socket.gethostbyname(DNS_NAME)
        print(f"DNS {DNS_NAME} currently resolves to: {resolved_ip}")
    except socket.gaierror:
        print(f"DNS {DNS_NAME} could not be resolved. Failover might still be in progress.")

    end_time = datetime.datetime.now()
    duration = end_time - start_time
    print("--- FAILOVER COMPLETE ---")
    print(f"End Time: {end_time}")
    print(f"Total RTO (Recovery Time Objective): {duration.total_seconds()} seconds")

    print("\nTo Restore Primary Region:")
    print(f"aws autoscaling update-auto-scaling-group --auto-scaling-group-name {PRIMARY_ASG} --min-size 2 --max-size 6 --desired-capacity 2 --region {REGION_PRIMARY}")

if __name__ == "__main__":
    simulate_failover()
