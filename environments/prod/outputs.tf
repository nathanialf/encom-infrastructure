# API Gateway outputs
output "api_gateway_endpoint" {
  description = "The invoke URL for the API Gateway"
  value       = module.api_gateway.api_endpoint
}

output "api_gateway_id" {
  description = "The ID of the API Gateway"
  value       = module.api_gateway.api_id
}

output "api_key" {
  description = "The API key for accessing the API (if enabled)"
  value       = var.enable_api_key ? module.api_gateway.api_key_value : null
  sensitive   = true
}

# Lambda outputs
output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "lambda_log_group" {
  description = "CloudWatch log group for Lambda function"
  value       = module.lambda.log_group_name
}

output "lambda_function_url" {
  description = "Lambda function URL (if enabled)"
  value       = module.lambda.function_url
}

output "api_gateway_url" {
  description = "Base URL of the API Gateway"
  value       = module.api_gateway.api_url
}

# Frontend outputs (when enabled)
output "frontend_bucket_name" {
  description = "Name of the S3 bucket for frontend hosting"
  value       = var.deploy_frontend ? module.frontend[0].bucket_name : null
}

output "frontend_url" {
  description = "URL of the frontend (CloudFront distribution or custom domain)"
  value       = var.deploy_frontend ? "https://encom.riperoni.com" : null
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = var.deploy_frontend ? module.frontend[0].distribution_id : null
}

# S3 Artifacts Bucket outputs
output "artifacts_bucket_name" {
  description = "Name of the S3 bucket for build artifacts"
  value       = aws_s3_bucket.build_artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket for build artifacts"
  value       = aws_s3_bucket.build_artifacts.arn
}

# SSL Certificate output
output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = var.deploy_frontend ? aws_acm_certificate.frontend[0].arn : null
}