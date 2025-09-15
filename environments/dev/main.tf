terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "encom-terraform-state-dev-us-west-1"
    key    = "encom-infrastructure/dev/terraform.tfstate"
    region = "us-west-1"
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "encom"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Account-level CloudWatch role not needed - each API Gateway has its own log group

# Local values for configuration
locals {
  project_name = "encom"
  environment  = "dev"
  
  # Lambda configuration
  lambda_function_name = "${local.project_name}-map-generator-${local.environment}"
  lambda_jar_path      = "/var/lib/jenkins/workspace/ENCOM-Shared/encom-lambda/build/libs/encom-lambda-1.0.0-all.jar"
  
  # API Gateway configuration  
  api_name = "${local.project_name}-api-${local.environment}"
  
  # Frontend configuration
  frontend_bucket_name = "${local.project_name}-frontend-${local.environment}-${data.aws_region.current.name}"
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    Region      = data.aws_region.current.name
    Account     = data.aws_caller_identity.current.account_id
  }
}

# Random string for unique bucket naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Lambda Module
module "lambda" {
  source = "../../modules/lambda"
  
  function_name    = local.lambda_function_name
  jar_file_path    = local.lambda_jar_path
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  log_retention_days = var.log_retention_days
  
  environment_variables = {
    DEFAULT_HEXAGON_COUNT = tostring(var.default_hexagon_count)
    MAX_HEXAGON_COUNT     = tostring(var.max_hexagon_count)
    CORRIDOR_RATIO        = tostring(var.corridor_ratio)
    ENVIRONMENT           = local.environment
  }
  
  enable_function_url           = var.enable_lambda_function_url
  enable_api_gateway_integration = false
  
  tags = merge(local.common_tags, {
    Component = "lambda"
  })
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"
  
  api_name          = local.api_name
  api_description   = "ENCOM Hexagonal Map Generator API - ${upper(local.environment)}"
  stage_name        = local.environment
  lambda_invoke_arn = module.lambda.function_invoke_arn
  
  
  enable_api_key        = var.enable_api_key
  throttle_rate_limit   = var.api_throttle_rate_limit
  throttle_burst_limit  = var.api_throttle_burst_limit
  quota_limit           = var.api_quota_limit
  log_retention_days    = var.log_retention_days
  
  tags = merge(local.common_tags, {
    Component = "api-gateway"
  })
  
  depends_on = [module.lambda]
}

# Lambda permission for API Gateway (created separately to avoid circular dependency)
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*/*"
  
  depends_on = [module.lambda, module.api_gateway]
}

# Frontend Module (optional for dev)
module "frontend" {
  count  = var.deploy_frontend ? 1 : 0
  source = "../../modules/frontend"
  
  bucket_name    = local.frontend_bucket_name
  index_document = "index.html"
  price_class    = "PriceClass_100"  # Cost-optimized for dev
  
  tags = merge(local.common_tags, {
    Component = "frontend"
  })
}