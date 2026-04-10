# AWS Infrastructure with Terraform, Ansible & CI/CD

[![Terraform CI/CD](https://github.com/Rashesh4/aws-infra-terraform/actions/workflows/terraform.yml/badge.svg)](https://github.com/Rashesh4/aws-infra-terraform/actions/workflows/terraform.yml)
![Terraform](https://img.shields.io/badge/Terraform-v1.8+-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-us--east--1-FF9900?logo=amazon-aws)
![Ansible](https://img.shields.io/badge/Ansible-Playbook-EE0000?logo=ansible)

Production-ready AWS infrastructure provisioned using **Terraform Registry modules**, with **Ansible** for configuration management and **GitHub Actions** for CI/CD automation.

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                       AWS Cloud (us-east-1)                      │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                       │  │
│  │                                                            │  │
│  │  ┌────────────────────┐    ┌────────────────────┐         │  │
│  │  │   Public Subnet    │    │   Private Subnet   │         │  │
│  │  │   10.0.1.0/24      │    │   10.0.10.0/24     │         │  │
│  │  │                    │    │                    │         │  │
│  │  │  ┌──────────────┐  │    │  (Reserved for     │         │  │
│  │  │  │ EC2 t2.micro │  │    │   future databases │         │  │
│  │  │  │   Nginx Web  │  │    │   and app servers) │         │  │
│  │  │  │   Server     │  │    │                    │         │  │
│  │  │  │  [IAM Role]  │  │    │                    │         │  │
│  │  │  └──────┬───────┘  │    └────────────────────┘         │  │
│  │  │         │          │                                    │  │
│  │  └─────────┼──────────┘                                    │  │
│  │            │                                               │  │
│  └────────────┼───────────────────────────────────────────────┘  │
│               │                                                  │
│       ┌───────┴────────┐           ┌──────────────────┐         │
│       │ Internet GW    │           │   S3 Bucket      │         │
│       └───────┬────────┘           │  ✓ Encrypted     │         │
│               │                    │  ✓ Versioned     │         │
│               │                    │  ✓ Lifecycle     │         │
└───────────────┼────────────────────┴──────────────────┘─────────┘
                │
          ┌─────┴──────┐
          │  Internet   │
          └─────┬──────┘
                │
   ┌────────────┴─────────────────────────┐
   │       GitHub Actions CI/CD           │
   │   fmt → validate → plan → apply      │
   └──────────────────────────────────────┘
```

---

## ✨ Features

| Component | Details |
|---|---|
| **VPC** | Custom VPC (10.0.0.0/16) with public and private subnets, Internet Gateway, DNS enabled |
| **EC2** | t2.micro Amazon Linux 2023, nginx web server, auto-configured via user_data |
| **S3** | Application bucket with versioning, AES-256 encryption, lifecycle policies, public access blocked |
| **IAM** | EC2 role with least-privilege S3 read access, instance profile attached |
| **Security Groups** | SSH (22), HTTP (80), HTTPS (443) ingress; all egress |
| **Ansible** | Optional playbook for nginx configuration and application deployment |
| **CI/CD** | GitHub Actions — format check, validate, plan on PR; apply on merge to main |
| **State** | Remote S3 backend with DynamoDB state locking |

---

## 📋 Prerequisites

| Tool | Version | Install Guide |
|---|---|---|
| [Terraform](https://www.terraform.io/downloads) | ≥ 1.0 | `choco install terraform` or [download](https://www.terraform.io/downloads) |
| [AWS CLI](https://aws.amazon.com/cli/) | ≥ 2.0 | `choco install awscli` or [download](https://aws.amazon.com/cli/) |
| [Git](https://git-scm.com/) | ≥ 2.0 | `choco install git` or [download](https://git-scm.com/) |
| [Ansible](https://docs.ansible.com/) | ≥ 2.9 | Linux/Mac only — `pip install ansible` |
| AWS Account | Free tier | [Sign up](https://aws.amazon.com/free/) |

---

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/Rashesh4/aws-infra-terraform.git
cd aws-infra-terraform
```

### 2. Configure AWS credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret, region (us-east-1), and output format
```

### 3. Generate SSH key pair

```bash
ssh-keygen -t ed25519 -f ~/.ssh/aws-infra-key -C "aws-infra" -N ""
```

### 4. Deploy the bootstrap (one-time setup)

```bash
cd bootstrap
terraform init
terraform plan
terraform apply -auto-approve

# Save the outputs — you'll need the GitHub Actions credentials
terraform output github_actions_access_key_id
terraform output -raw github_actions_secret_access_key
```

### 5. Deploy the infrastructure

```bash
cd ../environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed

terraform init
terraform plan
terraform apply
```

### 6. Verify the deployment

```bash
# Get the web URL
terraform output web_url

# SSH into the instance
eval $(terraform output -raw ssh_command)
```

### 7. (Optional) Run Ansible playbook

```bash
# Update ansible/inventory.ini with the EC2 public IP
cd ../../ansible
ansible-playbook playbook.yml
```

---

## 📁 Project Structure

```
aws-infra-terraform/
├── bootstrap/                      # One-time setup for Terraform backend
│   ├── main.tf                     # S3 state bucket + DynamoDB lock table + CI/CD IAM user
│   ├── variables.tf                # Bootstrap variable declarations
│   └── outputs.tf                  # State bucket info + GitHub Actions credentials
├── environments/
│   └── dev/
│       ├── providers.tf            # AWS provider config + S3 backend
│       ├── variables.tf            # Variable declarations with defaults
│       ├── locals.tf               # Local values for naming and tagging
│       ├── data.tf                 # Data sources (AMI lookup, account ID)
│       ├── main.tf                 # Module calls: VPC, SG, EC2, S3, IAM
│       ├── outputs.tf              # Resource IDs, IPs, connection info
│       └── terraform.tfvars.example # Example variable values
├── ansible/
│   ├── ansible.cfg                 # Ansible configuration
│   ├── inventory.ini               # Static inventory (update with EC2 IP)
│   └── playbook.yml                # Server configuration playbook
├── scripts/
│   └── user_data.sh                # EC2 bootstrap script (nginx setup)
├── .github/
│   └── workflows/
│       └── terraform.yml           # CI/CD pipeline (fmt → validate → plan → apply)
├── .gitignore                      # Git ignore rules
├── .terraform-version              # Pinned Terraform version
├── README.md                       # This file
└── PROCESS.md                      # AI usage and decision documentation
```

---

## 🔧 Terraform Registry Modules

| Module | Version | Purpose |
|---|---|---|
| [terraform-aws-modules/vpc/aws](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) | ~> 5.0 | VPC, subnets, Internet Gateway, routing |
| [terraform-aws-modules/security-group/aws](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws) | ~> 5.0 | Security group with ingress/egress rules |
| [terraform-aws-modules/ec2-instance/aws](https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws) | ~> 5.0 | EC2 instance provisioning |
| [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws) | ~> 4.0 | S3 bucket with versioning, encryption, lifecycle |

---

## 🔄 CI/CD Pipeline

The GitHub Actions workflow runs automatically on pull requests and pushes to `main`:

```
┌──────────┐     ┌────────────┐     ┌──────────┐     ┌──────────┐
│  📐 fmt   │────▶│ ✅ validate │────▶│ 📋 plan  │────▶│ 🚀 apply │
│  check   │     │            │     │          │     │ (main    │
│          │     │            │     │          │     │  only)   │
└──────────┘     └────────────┘     └──────────┘     └──────────┘
```

| Stage | Trigger | What it does |
|---|---|---|
| **Format** | PR + Push | Ensures code follows `terraform fmt` standards |
| **Validate** | PR + Push | Checks syntax and internal consistency |
| **Plan** | PR + Push | Shows what resources will be created/changed |
| **Apply** | Push to main only | Creates/updates AWS resources |

### Setting up CI/CD

1. Go to **GitHub repo → Settings → Secrets and variables → Actions**
2. Add these secrets (from bootstrap outputs):
   - `AWS_ACCESS_KEY_ID` — from `terraform output github_actions_access_key_id`
   - `AWS_SECRET_ACCESS_KEY` — from `terraform output -raw github_actions_secret_access_key`
3. Go to **Settings → Environments → New environment** → name it `production`

---

## 🔒 Security Considerations

### Implemented

- ✅ S3 bucket: all public access blocked
- ✅ S3 bucket: AES-256 server-side encryption
- ✅ S3 bucket: versioning enabled for data recovery
- ✅ EC2 root volume: encrypted
- ✅ IAM role: least-privilege S3 read access only
- ✅ CI/CD IAM user: scoped permissions (no admin access)
- ✅ SSH key-based authentication (no passwords)
- ✅ Terraform state: encrypted at rest in S3
- ✅ State locking: DynamoDB prevents concurrent modifications

### Production Recommendations

- 🔲 Restrict SSH CIDR to specific IP ranges
- 🔲 Enable VPC Flow Logs for network monitoring
- 🔲 Add NAT Gateway for private subnet internet access
- 🔲 Enable AWS CloudTrail for API audit logging
- 🔲 Use AWS Secrets Manager for sensitive values
- 🔲 Implement HTTPS with ACM certificate and ALB
- 🔲 Add CloudWatch alarms for EC2 monitoring

---

## 💰 Cost Estimate

| Resource | Free Tier | Monthly Cost (post free tier) |
|---|---|---|
| EC2 t2.micro | 750 hrs/month (12 months) | ~$8.35/month |
| S3 Bucket | 5 GB storage | ~$0.02/GB |
| DynamoDB (state lock) | 25 GB + 25 WCU/RCU | ~$0.00 |
| Internet Gateway | Free | $0.00 |
| Data Transfer | 1 GB/month out | ~$0.09/GB |

> **💡 Tip:** Always run `terraform destroy` after testing to avoid unexpected charges.

---

## 🧹 Cleanup

```bash
# 1. Destroy main infrastructure
cd environments/dev
terraform destroy -auto-approve

# 2. Destroy bootstrap resources (optional)
cd ../../bootstrap
aws s3 rm s3://rashesh-terraform-state-2026 --recursive
terraform destroy -auto-approve
```

---

## 📄 License

This project is created as a technical assessment. See [PROCESS.md](PROCESS.md) for detailed documentation of the development process and AI tool usage.
