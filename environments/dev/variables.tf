# =============================================================================
# Variable Declarations
# =============================================================================

# ---- General ----------------------------------------------------------------
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "web-platform"
}

# ---- VPC --------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.10.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a"]
}

# ---- EC2 --------------------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ssh_public_key_material" {
  description = "The actual SSH public key string (used in CI/CD). If empty, falls back to local file."
  type        = string
  default     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXR69f3KM8l8Nd9rPsjRcflR0cCba/MlFkCcwcl4uMV rashesh-aws-infra"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file (used for local deployments)"
  type        = string
  default     = "~/.ssh/aws-infra-key.pub"
}

# ---- S3 ---------------------------------------------------------------------
variable "app_bucket_prefix" {
  description = "Prefix for the application S3 bucket name"
  type        = string
  default     = "rashesh-web-platform"
}

# ---- Access Control ----------------------------------------------------------
variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to SSH into EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict to your IP in production
}
