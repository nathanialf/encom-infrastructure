# Production Environment Configuration for ENCOM Infrastructure

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  
  backend "s3" {
    bucket = "encom-terraform-state-prod-us-west-1"
    key    = "encom/prod/terraform.tfstate"
    region = "us-west-1"
  }
}

# Configure AWS Provider
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "encom"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# AWS Provider for us-east-1 (required for CloudFront certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  
  default_tags {
    tags = {
      Project     = "encom"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Random suffix for unique bucket names (if needed)
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Local values
locals {
  project_name = "encom"
  environment  = "prod"
  
  # Lambda configuration
  lambda_function_name = "${local.project_name}-map-generator-${local.environment}"
  lambda_jar_path      = "/var/lib/jenkins/workspace/ENCOM-Shared/encom-lambda/build/libs/encom-lambda-1.0.0-all.jar"
  
  # API Gateway configuration  
  api_name = "${local.project_name}-api-${local.environment}"
  
  # Frontend configuration
  frontend_bucket_name = "${local.project_name}-frontend-${local.environment}-${data.aws_region.current.name}"
  artifacts_bucket_name = "${local.project_name}-build-artifacts-${local.environment}-${data.aws_region.current.name}"
  
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    Account     = data.aws_caller_identity.current.account_id
    Region      = data.aws_region.current.name
  }
}

# S3 Bucket for build artifacts
resource "aws_s3_bucket" "build_artifacts" {
  bucket = local.artifacts_bucket_name
  
  tags = merge(local.common_tags, {
    Component = "artifacts"
    Name      = "Build Artifacts"
  })
}

resource "aws_s3_bucket_versioning" "build_artifacts" {
  bucket = aws_s3_bucket.build_artifacts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "build_artifacts" {
  bucket = aws_s3_bucket.build_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Lambda Module
module "lambda" {
  source = "../../modules/lambda"
  
  function_name       = local.lambda_function_name
  jar_file_path      = local.lambda_jar_path
  memory_size = var.lambda_memory_size
  timeout     = var.lambda_timeout
  log_retention_days = var.log_retention_days
  
  environment_variables = {
    DEFAULT_HEXAGON_COUNT = "50"
    MAX_HEXAGON_COUNT     = "500"  # Higher limit for prod
    CORRIDOR_RATIO        = "0.7"
    ENVIRONMENT          = "prod"
  }
  
  tags = merge(local.common_tags, {
    Component = "lambda"
  })
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"
  
  api_name           = local.api_name
  lambda_invoke_arn  = module.lambda.function_invoke_arn
  enable_api_key     = var.enable_api_key
  
  # Rate limiting configuration
  throttle_rate_limit  = var.api_throttle_rate_limit
  throttle_burst_limit = var.api_throttle_burst_limit
  quota_limit         = var.api_quota_limit
  
  log_retention_days = var.log_retention_days
  
  tags = merge(local.common_tags, {
    Component = "api-gateway"
  })
  
  depends_on = [module.lambda]
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  
  source_arn = "${module.api_gateway.api_execution_arn}/*/*"
  
  depends_on = [module.lambda, module.api_gateway]
}

# ACM Certificate for encom.riperoni.com (must be in us-east-1 for CloudFront)
resource "aws_acm_certificate" "frontend" {
  provider          = aws.us_east_1
  count             = var.deploy_frontend ? 1 : 0
  domain_name       = "encom.riperoni.com"
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(local.common_tags, {
    Component = "frontend"
    Name      = "encom.riperoni.com"
  })
}

# Frontend Module (optional for prod)
module "frontend" {
  count  = var.deploy_frontend ? 1 : 0
  source = "../../modules/frontend"
  
  bucket_name         = local.frontend_bucket_name
  index_document      = "index.html"
  price_class         = "PriceClass_All"  # Global distribution for prod
  domain_name         = "encom.riperoni.com"
  ssl_certificate_arn = var.deploy_frontend ? aws_acm_certificate.frontend[0].arn : ""
  
  tags = merge(local.common_tags, {
    Component = "frontend"
  })
  
  depends_on = [aws_acm_certificate.frontend]
}