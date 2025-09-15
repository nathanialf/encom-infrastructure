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

# Create S3 bucket for Terraform state
module "terraform_state" {
  source = "../modules/terraform-state"
  
  bucket_name = "encom-terraform-state-dev-us-west-1"
  
  tags = {
    Project     = "encom"
    Environment = "dev"
    Component   = "terraform-state"
  }
}