# =============================================================================
# Data Sources
# =============================================================================

# Fetch latest Amazon Linux 2023 AMI dynamically
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Get current AWS account ID (used for unique S3 bucket naming)
data "aws_caller_identity" "current" {}

# Get current region
data "aws_region" "current" {}
