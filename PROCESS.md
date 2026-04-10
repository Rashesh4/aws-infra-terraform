# Process Documentation — How This Solution Was Built

This document records the system prompts, AI tool usage, architectural decisions, and problem-solving approach used to build this AWS infrastructure project. Transparency and honest documentation of the development process was a requirement of this assessment.

---

## 🛠️ Tools Used

| Tool | Purpose |
|---|---|
| **Cursor / AI Assistant** | Infrastructure design, Terraform module configuration, CI/CD pipeline creation |
| **Terraform CLI** | Infrastructure provisioning and validation |
| **AWS CLI** | AWS credential management and resource verification |
| **Git + GitHub** | Version control and CI/CD integration |

---

## 🏛️ Architecture Decisions

### 1. Terraform Registry Modules vs. Raw Resources

**Decision:** Use official Terraform Registry modules (`terraform-aws-modules/*`) instead of writing raw `aws_*` resources.

**Rationale:**
- Community-maintained, battle-tested by thousands of users
- Best practices baked in (proper tagging, security defaults)
- Significantly less code — focus on *configuration* over *implementation*
- Version pinning ensures reproducibility across environments
- Aligns with the test requirement: *"Terraform Registry modules"*

**AI Usage:** Used AI to identify the correct module versions and configure module inputs. Cross-referenced against official Terraform Registry documentation to verify correctness.

---

### 2. S3 Remote Backend with DynamoDB Locking

**Decision:** Store Terraform state in S3 with DynamoDB state locking, deployed via a separate bootstrap config.

**Rationale:**
- **Team collaboration:** Multiple engineers can safely work on the same infrastructure
- **State locking:** DynamoDB prevents concurrent `terraform apply` executions that could corrupt state
- **Encryption at rest:** S3 bucket uses AES-256 encryption
- **Versioning:** S3 versioning enables state rollback if something goes wrong
- **Bootstrap pattern:** The state backend resources must exist before the main config, so they're managed separately — this is the standard industry pattern

**AI Usage:** Used AI to structure the bootstrap Terraform configuration and IAM policies. I decided the separation pattern and security posture myself.

---

### 3. Amazon Linux 2023 over Ubuntu

**Decision:** Use Amazon Linux 2023 (AL2023) as the EC2 operating system.

**Rationale:**
- Official AWS-supported AMI, optimized for EC2
- Long-term support with regular security patches from Amazon
- Better integration with AWS services (SSM Agent pre-installed, etc.)
- Uses `dnf` package manager (modern, replacing `yum`)

**AI Usage:** Used AI to find the correct AMI filter pattern for dynamic AMI lookup via `data.aws_ami`.

---

### 4. Network Design

**Decision:** VPC with 10.0.0.0/16 CIDR, 1 public subnet (10.0.1.0/24), 1 private subnet (10.0.10.0/24), no NAT Gateway.

**Rationale:**
- `/16` CIDR provides 65,536 addresses — room for future growth
- Public subnet for the web server (needs direct internet access)
- Private subnet reserved for future databases/application servers
- No NAT Gateway in dev to save costs (~$32/month); would add in production
- Internet Gateway for outbound access from public subnet

**AI Usage:** I determined the CIDR ranges and subnet layout. AI helped with the VPC module configuration syntax.

---

### 5. IAM with Least Privilege

**Decision:** Create a dedicated IAM role for EC2 with only S3 read access to the specific application bucket.

**Rationale:**
- **Principle of least privilege:** The EC2 instance only needs to read from S3
- **Scoped to one bucket:** Policy explicitly references only the app bucket ARN, not `*`
- **Instance profile pattern:** Avoids storing AWS credentials on the EC2 instance
- **CI/CD IAM user:** Also scoped to only the permissions needed for Terraform operations

**AI Usage:** Used AI to construct the IAM policy JSON with correct action and resource specifications. I defined the required permissions scope.

---

### 6. CI/CD Pipeline Design

**Decision:** 4-stage GitHub Actions pipeline: fmt → validate → plan → apply.

**Rationale:**
- **Format check:** Catches formatting inconsistencies before review
- **Validate:** Catches syntax errors before attempting to plan
- **Plan:** Shows exactly what will change — reviewable in PR
- **Apply:** Only on merge to main, with environment protection
- **Artifact passing:** Plan is saved and reused in apply to ensure consistency

**AI Usage:** Used AI for GitHub Actions YAML syntax and the artifact upload/download pattern between jobs. I designed the pipeline flow and conditional logic.

---

### 7. S3 Bucket Configuration

**Decision:** Application bucket with versioning, AES-256 encryption, lifecycle rules (IA after 30 days), and all public access blocked.

**Rationale:**
- **Versioning:** Enables recovery of accidentally deleted/overwritten objects
- **Encryption:** Data at rest protection — compliance best practice
- **Lifecycle rule:** Automatically transitions infrequently accessed data to cheaper storage class
- **Public access block:** Defense in depth — prevents accidental public exposure

**AI Usage:** Used AI for the S3 module lifecycle rule syntax. Security decisions were mine.

---

## 🧠 Key Prompts & AI Interactions

### Infrastructure Design Phase
- "Design a VPC with public and private subnets using the terraform-aws-modules/vpc module"
- "Create IAM role with least-privilege S3 read access for EC2"
- "Configure S3 bucket with versioning, encryption, and lifecycle transition to IA"

### CI/CD Phase
- "Create GitHub Actions workflow for Terraform with fmt, validate, plan, and apply stages"
- "How to pass terraform plan as artifact between GitHub Actions jobs"

### Documentation Phase
- "Generate an architecture diagram for VPC with EC2, S3, and Internet Gateway"
- "Structure a README for a Terraform infrastructure project"

In each case, I reviewed the AI-generated output, verified against official documentation, and made modifications based on my understanding of the requirements and best practices.

---

## 🐛 Challenges & Solutions

*(Document actual challenges encountered during deployment below)*

| Challenge | Solution |
|---|---|
| | |
| | |

---

## 📝 Key Learnings

*(Document learnings during implementation below)*

1.
2.
3.

---

## ⏱️ Time Log

| Phase | Time Spent | Activities |
|---|---|---|
| Planning & Design | | Architecture decisions, module selection |
| Terraform Code | | VPC, EC2, S3, IAM, Security Groups |
| Bootstrap Setup | | S3 backend, DynamoDB, CI/CD IAM user |
| CI/CD Pipeline | | GitHub Actions workflow |
| Ansible | | Playbook for nginx configuration |
| Documentation | | README, PROCESS.md |
| Testing | | terraform plan/apply, verification |
| **Total** | | |
