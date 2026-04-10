# =============================================================================
# Outputs
# =============================================================================

# ---- VPC --------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnets
}

# ---- EC2 --------------------------------------------------------------------
output "ec2_instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2_instance.id
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2_instance.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2_instance.public_dns
}

# ---- S3 --------------------------------------------------------------------
output "s3_bucket_name" {
  description = "Name of the application S3 bucket"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the application S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

# ---- Security Group ---------------------------------------------------------
output "security_group_id" {
  description = "ID of the web security group"
  value       = module.web_security_group.security_group_id
}

# ---- IAM --------------------------------------------------------------------
output "ec2_iam_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

# ---- Connection Info --------------------------------------------------------
output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ~/.ssh/aws-infra-key ec2-user@${module.ec2_instance.public_ip}"
}

output "web_url" {
  description = "URL to access the web server"
  value       = "http://${module.ec2_instance.public_ip}"
}
