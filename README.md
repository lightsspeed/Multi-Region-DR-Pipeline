# Multi-Region DR Pipeline Project

This project deploys a complete Multi-Region Disaster Recovery (DR) pipeline on AWS using Terraform.

## Architecture

The infrastructure consists of a Primary Region (Active) and a DR Region (Standby). Traffic is routed via Route 53 Global DNS. State is persisted in an Amazon RDS database with asynchronous Cross-Region Replication to the DR region.

```mermaid
graph TB
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:#fff;
    classDef compute fill:#E7157B,stroke:#232F3E,stroke-width:2px,color:#fff;
    classDef db fill:#3F8624,stroke:#232F3E,stroke-width:2px,color:#fff;
    classDef dns fill:#8C4FFF,stroke:#232F3E,stroke-width:2px,color:#fff;
    classDef region fill:#f9f9f9,stroke:#333,stroke-width:2px,stroke-dasharray: 4 4;
    classDef vpc fill:#e6f2ff,stroke:#0066cc,stroke-width:2px;
    classDef pub_sub fill:#e6ffe6,stroke:#009933,stroke-width:1px;
    classDef priv_sub fill:#ffebcc,stroke:#e67300,stroke-width:1px;

    %% Global Services
    DNS((Route 53 Global DNS)):::dns

    %% Primary Region
    subgraph Primary_Region [Primary Region: ap-south-1]
        direction TB
        class Primary_Region region
        
        subgraph Primary_VPC [Primary VPC]
            class Primary_VPC vpc
            
            subgraph Primary_Public [Primary Public Subnet]
                class Primary_Public pub_sub
                ALB_P[Application Load Balancer]:::aws
            end
            
            subgraph Primary_Private [Primary Private Subnet]
                class Primary_Private priv_sub
                ASG_P[Auto Scaling Group]:::compute
                RDS_P[(Amazon RDS Primary)]:::db
            end
        end
        ALB_P -->|Forward Traffic| ASG_P
        ASG_P -->|Read & Write| RDS_P
    end

    %% DR Region
    subgraph DR_Region [DR Region: ap-southeast-1]
        direction TB
        class DR_Region region
        
        subgraph DR_VPC [DR VPC]
            class DR_VPC vpc
            
            subgraph DR_Public [DR Public Subnet]
                class DR_Public pub_sub
                ALB_D[Application Load Balancer]:::aws
            end
            
            subgraph DR_Private [DR Private Subnet]
                class DR_Private priv_sub
                ASG_D[Auto Scaling Group]:::compute
                RDS_D[(Amazon RDS Replica)]:::db
            end
        end
        ALB_D -.->|Forward Traffic| ASG_D
        ASG_D -.->|Read Only| RDS_D
    end

    %% Global Routing (Defined at end to keep rank balanced)
    DNS -->|Primary Active| ALB_P
    DNS -.->|Failover| ALB_D

    %% Cross-Region Data Flow (Dotted to prevent vertical offset)
    RDS_P -.->|Async Replication| RDS_D
```

![Architecture Diagram](docs/architecture.png)

## Project Structure
```text
dr-pipeline/
├── terraform/          # Infrastructure as Code
├── app/                # Flask Health-check & testing App
├── scripts/            # Python & Powershell Scripts for Simulation
└── README.md
```

## Setup & Deployment

1. **Pre-requisites**
   - AWS CLI configured with admin credentials.
   - Terraform installed.
   - Python 3 with `pip install -r requirements.txt`.

2. **Deployment**
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

## DR Pipeline Simulation

1. **Seed Data (Writes to Primary)**
   ```powershell
   .\seed_data.ps1
   ```
   Or `python seed_data.py`
2. **Check Health (Validates Primary ALB/ASG)**
   ```bash
   python check_health.py
   ```
3. **Verify Replication (Reads from DR Replica)**
   ```bash
   python verify_replication.py
   ```
4. **Simulate Failover (Promotes DR database & Updates Route53)**
   ```bash
   python simulate_failover.py
   ```

## Clean Up
```bash
cd terraform
terraform destroy
```
