output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "lambda_function_url" {
  description = "Lambda function URL (if enabled)"
  value       = module.lambda.function_url
}

output "api_gateway_url" {
  description = "Base URL of the API Gateway"
  value       = module.api_gateway.api_url
}

output "api_gateway_endpoint" {
  description = "Full endpoint URL for map generation"
  value       = module.api_gateway.api_endpoint
}

output "api_key_value" {
  description = "API key value (if enabled)"
  value       = module.api_gateway.api_key_value
  sensitive   = true
}

output "frontend_url" {
  description = "Frontend website URL (if deployed)"
  value       = var.deploy_frontend ? module.frontend[0].website_url : null
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (if frontend deployed)"
  value       = var.deploy_frontend ? module.frontend[0].cloudfront_distribution_id : null
}

