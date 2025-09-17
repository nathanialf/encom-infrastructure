terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure AWS Provider
provider "aws" {
  region = "us-west-1"
  
  default_tags {
    tags = {
      Project     = "encom"
      Environment = "bootstrap"
      ManagedBy   = "terraform"
      Purpose     = "state-management"
    }
  }
}

# Variables
variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

# Create S3 bucket for Terraform state
module "terraform_state" {
  source = "../modules/terraform-state"
  
  bucket_name = "encom-terraform-state-${var.environment}-us-west-1"
  
  tags = {
    Project     = "encom"
    Environment = var.environment
    Component   = "terraform-state"
  }
}