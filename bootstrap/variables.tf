variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of S3 bucket for Terraform state"
  type        = string
  default     = "rashesh-terraform-state-2026"
}

variable "lock_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "terraform-state-locks"
}
