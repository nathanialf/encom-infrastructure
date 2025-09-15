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

# Custom domain outputs
output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = module.api_gateway.custom_domain_name
}

output "custom_api_endpoint" {
  description = "Custom domain API endpoint (if configured)"
  value       = module.api_gateway.custom_api_endpoint
}

output "certificate_arn" {
  description = "ARN of the SSL certificate (if created)"
  value       = module.api_gateway.certificate_arn
}

output "certificate_validation_records" {
  description = "DNS validation records for certificate (if created)"
  value       = module.api_gateway.certificate_validation_records
  sensitive   = false
}

# Useful information for testing
output "test_curl_command" {
  description = "Example curl command to test the API"
  value = var.enable_api_key ? "curl -X POST '${module.api_gateway.api_endpoint}' -H 'x-api-key: ${module.api_gateway.api_key_value}' -H 'Content-Type: application/json' -d '{\"hexagonCount\": 25}'" : "curl -X POST '${module.api_gateway.api_endpoint}' -H 'Content-Type: application/json' -d '{\"hexagonCount\": 25}'"
  sensitive = false
}

output "test_curl_command_custom" {
  description = "Example curl command using custom domain (if configured)"
  value = var.custom_domain_name != null ? (var.enable_api_key ? "curl -X POST '${module.api_gateway.custom_api_endpoint}' -H 'x-api-key: ${module.api_gateway.api_key_value}' -H 'Content-Type: application/json' -d '{\"hexagonCount\": 25}'" : "curl -X POST '${module.api_gateway.custom_api_endpoint}' -H 'Content-Type: application/json' -d '{\"hexagonCount\": 25}'") : "Custom domain not configured"
  sensitive = false
}