# =============================================================================
# Main Infrastructure Configuration
# Uses Terraform Registry modules for VPC, Security Group, EC2, and S3
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Module — terraform-aws-modules/vpc/aws
# Creates VPC with public and private subnets, internet gateway, and routing
# -----------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  # Internet Gateway for public subnet
  create_igw = true

  # No NAT Gateway (cost optimization for dev environment)
  enable_nat_gateway = false

  # DNS settings — required for public DNS hostnames on EC2
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet tags for identification
  public_subnet_tags = {
    Type = "public"
  }

  private_subnet_tags = {
    Type = "private"
  }

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Security Group Module — terraform-aws-modules/security-group/aws
# Allows SSH (22), HTTP (80), HTTPS (443) ingress; all egress
# -----------------------------------------------------------------------------
module "web_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web server - allows SSH, HTTP, HTTPS"
  vpc_id      = module.vpc.vpc_id

  # Ingress rules
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH access"
      cidr_blocks = join(",", var.allowed_ssh_cidrs)
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP access"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS access"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  # Egress — allow all outbound traffic
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SSH Key Pair
# Uploads local public key to AWS for EC2 access
# -----------------------------------------------------------------------------
resource "aws_key_pair" "deployer" {
  key_name   = "${local.name_prefix}-key"
  public_key = var.ssh_public_key_material != "" ? var.ssh_public_key_material : try(file(var.ssh_public_key_path), "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI_dummy_key_for_ci_validation")

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# IAM Role & Instance Profile for EC2
# Grants EC2 read-only access to the application S3 bucket (least privilege)
# -----------------------------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "${local.name_prefix}-s3-read-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# EC2 Instance Module — terraform-aws-modules/ec2-instance/aws
# Web server in public subnet with nginx installed via user_data
# -----------------------------------------------------------------------------
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-web-server"

  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [module.web_security_group.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]

  # Associate public IP for internet access
  associate_public_ip_address = true

  # Attach IAM instance profile for S3 access
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # User data script to bootstrap nginx on first boot
  user_data = file("${path.module}/../../scripts/user_data.sh")

  # Root volume configuration
  root_block_device = [
    {
      volume_type           = "gp3"
      volume_size           = 20
      delete_on_termination = true
      encrypted             = true
    }
  ]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-server"
    Role = "webserver"
  })
}

# -----------------------------------------------------------------------------
# S3 Bucket Module — terraform-aws-modules/s3-bucket/aws
# Application bucket with versioning, encryption, lifecycle, public access blocked
# -----------------------------------------------------------------------------
module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = "${var.app_bucket_prefix}-${data.aws_caller_identity.current.account_id}"

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Enable versioning
  versioning = {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Lifecycle rules — transition to Infrequent Access after 30 days
  lifecycle_rule = [
    {
      id      = "transition-to-ia"
      enabled = true

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]

      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]

  tags = local.common_tags
}
