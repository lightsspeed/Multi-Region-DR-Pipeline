import boto3
import json

def check_tg_health():
    client = boto3.client('elbv2', region_name='ap-south-1')
    tgs = client.describe_target_groups()
    
    for tg in tgs['TargetGroups']:
        arn = tg['TargetGroupArn']
        name = tg['TargetGroupName']
        print(f"\nChecking Target Group: {name}")
        
        health = client.describe_target_health(TargetGroupArn=arn)
        if not health['TargetHealthDescriptions']:
            print("  - No targets found in this group.")
        for target in health['TargetHealthDescriptions']:
            target_id = target['Target']['Id']
            status = target['TargetHealth']['State']
            reason = target['TargetHealth'].get('Reason', 'N/A')
            desc = target['TargetHealth'].get('Description', 'N/A')
            print(f"  - Target {target_id}: {status} (Reason: {reason}, Desc: {desc})")

if __name__ == "__main__":
    check_tg_health()
