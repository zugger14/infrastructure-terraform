terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "multiapp-terraform-state-615993872381"
    key            = "platform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "MultiApp-Platform"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
