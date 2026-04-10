output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

# GitHub Actions CI/CD credentials
output "github_actions_access_key_id" {
  description = "AWS Access Key ID for GitHub Actions — add to GitHub Secrets"
  value       = aws_iam_access_key.github_actions.id
}

output "github_actions_secret_access_key" {
  description = "AWS Secret Access Key for GitHub Actions — add to GitHub Secrets"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "github_actions_iam_user_arn" {
  description = "ARN of the GitHub Actions IAM user"
  value       = aws_iam_user.github_actions.arn
}
