output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "function_qualified_arn" {
  description = "Qualified ARN of the Lambda function with alias"
  value       = aws_lambda_alias.function_alias.arn
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.function.invoke_arn
}

output "function_url" {
  description = "Lambda function URL (if enabled)"
  value       = var.enable_function_url ? aws_lambda_function_url.function_url[0].function_url : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.lambda_role.name
}

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "alias_name" {
  description = "Name of the Lambda alias"
  value       = aws_lambda_alias.function_alias.name
}

output "alias_arn" {
  description = "ARN of the Lambda alias"
  value       = aws_lambda_alias.function_alias.arn
}