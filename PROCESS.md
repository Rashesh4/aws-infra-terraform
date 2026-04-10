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

| Challenge | Solution |
|---|---|
| **IAM Inline Policy Limit** — The CI/CD IAM policy was originally an inline policy, which failed because it exceeded the AWS 2048-character limit. | Split the single inline policy into multiple AWS Managed Policies (`aws_iam_policy`) and attached them using `aws_iam_user_policy_attachment`. |
| **SSH Key in CI/CD** — The `aws_key_pair` resource relied on a local file path (`~/.ssh/...`), causing the GitHub Action to fail because the file didn't exist in the CI runner. | Added a highly flexible fallback using `var.ssh_public_key_material`. In CI/CD, the key is passed directly via variable, skipping the local file read while keeping local terraform functional. |
| **Non-ASCII Characters** — AWS API rejected the deployment due to an "em dash" (—) in the security group description. | Simplified all AWS resource descriptions in Terraform to strictly use basic ASCII characters. |

---

## 📝 Key Learnings

1. **IAM Policy Structuring:** Inline user policies are severely constrained in size. For complex CI/CD permissions involving multiple services, standalone Managed Policies are required.
2. **Hybrid Local/CI Workflows:** Care must be taken when depending on local filesystem paths (`file()`) in Terraform. It breaks when executed on remote runners unless accounted for with conditionals or default variable text.
3. **AWS API Quirks:** Not all strings are treated equally by AWS. Descriptions in security groups must be strictly ASCII to prevent deployment failure.

---

## ⏱️ Time Log

| Phase | Time Spent | Activities |
|---|---|---|
| Planning & Design | 30 mins | Architecture decisions, module selection |
| Terraform Code | 1 hour | VPC, EC2, S3, IAM, Security Groups configuration |
| Bootstrap Setup | 30 mins | S3 backend, DynamoDB, CI/CD IAM user, IAM limits debugging |
| CI/CD Pipeline | 45 mins | GitHub Actions workflow, debugging SSH key injection |
| Ansible | 30 mins | Playbook for nginx configuration, updating inventory |
| Documentation | 30 mins | README, PROCESS.md, creating plan and outputs |
| Testing | 15 mins | terraform plan/apply, visual verification of Nginx |
| **Total** | **~4 hours** | Complete Infrastructure Automation implementation |
