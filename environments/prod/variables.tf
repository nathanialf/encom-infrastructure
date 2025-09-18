variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-west-1"
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "enable_lambda_function_url" {
  description = "Enable Lambda function URL for direct HTTP access"
  type        = bool
  default     = false
}

# Map Generation Configuration
variable "default_hexagon_count" {
  description = "Default number of hexagons to generate"
  type        = number
  default     = 50
}

variable "max_hexagon_count" {
  description = "Maximum number of hexagons allowed"
  type        = number
  default     = 200
}

variable "corridor_ratio" {
  description = "Default corridor to room ratio"
  type        = number
  default     = 0.7
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30  # Longer retention for production
}

variable "enable_api_key" {
  description = "Enable API key authentication"
  type        = bool
  default     = true  # API key required for production
}

variable "api_throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 100  # Higher rate limit for production
}

variable "api_throttle_burst_limit" {
  description = "API Gateway throttle burst limit"
  type        = number
  default     = 200  # Higher burst limit for production
}

variable "api_quota_limit" {
  description = "API Gateway quota limit (requests per month)"
  type        = number
  default     = 100000  # Higher quota for production
}

variable "deploy_frontend" {
  description = "Deploy frontend infrastructure (S3 + CloudFront)"
  type        = bool
  default     = true  # Frontend enabled by default for production
}