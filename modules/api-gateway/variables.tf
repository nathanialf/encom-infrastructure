variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "api_description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "ENCOM Hexagonal Map Generator API"
}

variable "stage_name" {
  description = "Stage name for API Gateway"
  type        = string
  default     = "dev"
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  type        = string
}

variable "enable_api_key" {
  description = "Enable API key authentication"
  type        = bool
  default     = true
}

variable "quota_limit" {
  description = "API quota limit per period"
  type        = number
  default     = 10000
}

variable "quota_period" {
  description = "API quota period"
  type        = string
  default     = "MONTH"
}

variable "throttle_rate_limit" {
  description = "Throttle rate limit (requests per second)"
  type        = number
  default     = 100
}

variable "throttle_burst_limit" {
  description = "Throttle burst limit"
  type        = number
  default     = 200
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "encom"
    Component   = "api-gateway"
    Environment = "dev"
  }
}