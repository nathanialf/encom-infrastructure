variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "jar_file_path" {
  description = "Path to the JAR file containing the Lambda function code"
  type        = string
}

variable "handler" {
  description = "Lambda function handler"
  type        = string
  default     = "com.encom.mapgen.handler.MapGeneratorHandler::handleRequest"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "java17"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 512
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default = {
    DEFAULT_HEXAGON_COUNT = "50"
    MAX_HEXAGON_COUNT     = "200"
    CORRIDOR_RATIO        = "0.7"
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "enable_function_url" {
  description = "Enable Lambda function URL for direct HTTP access"
  type        = bool
  default     = false
}

variable "enable_api_gateway_integration" {
  description = "Enable API Gateway integration"
  type        = bool
  default     = true
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN for Lambda permissions"
  type        = string
  default     = ""
}

variable "alias_name" {
  description = "Alias name for Lambda function"
  type        = string
  default     = "live"
}

variable "custom_policy_statements" {
  description = "Additional IAM policy statements for Lambda role"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "encom"
    Component   = "lambda"
    Environment = "dev"
  }
}