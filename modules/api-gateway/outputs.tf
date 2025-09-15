output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.api.id
}

output "api_arn" {
  description = "ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.api.arn
}

output "api_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.api.execution_arn
}

output "api_url" {
  description = "URL of the API Gateway stage"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}"
}

output "api_endpoint" {
  description = "Full endpoint URL for map generation"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${var.stage_name}/api/v1/map/generate"
}

output "api_key_id" {
  description = "ID of the API key (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.api_key[0].id : null
}

output "api_key_value" {
  description = "Value of the API key (if enabled)"
  value       = var.enable_api_key ? aws_api_gateway_api_key.api_key[0].value : null
  sensitive   = true
}

output "usage_plan_id" {
  description = "ID of the usage plan (if API key enabled)"
  value       = var.enable_api_key ? aws_api_gateway_usage_plan.usage_plan[0].id : null
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.stage.stage_name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.api_gateway_logs.name
}

output "custom_domain_name" {
  description = "Custom domain name (if configured)"
  value       = var.custom_domain_name != null ? aws_api_gateway_domain_name.custom_domain[0].domain_name : null
}

output "custom_domain_target" {
  description = "Target domain name for DNS setup (if custom domain configured)"
  value       = var.custom_domain_name != null ? aws_api_gateway_domain_name.custom_domain[0].domain_name : null
}

output "custom_api_endpoint" {
  description = "Custom domain API endpoint (if configured)"
  value       = var.custom_domain_name != null ? "https://${var.custom_domain_name}/api/v1/map/generate" : null
}

output "certificate_arn" {
  description = "ARN of the SSL certificate (if created)"
  value       = var.custom_domain_name != null && var.create_certificate ? aws_acm_certificate.custom_domain_cert[0].arn : null
}

output "certificate_validation_records" {
  description = "DNS validation records for certificate (if created)"
  value       = var.custom_domain_name != null && var.create_certificate ? aws_acm_certificate.custom_domain_cert[0].domain_validation_options : null
}