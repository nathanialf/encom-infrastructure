output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.terraform_state.s3_bucket_name
}

output "backend_configuration" {
  description = "Backend configuration for main Terraform"
  value = {
    bucket = module.terraform_state.s3_bucket_name
    key    = "encom-infrastructure/dev/terraform.tfstate"
    region = "us-west-1"
  }
}