terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {} # just for this setup step
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

   tags = {
    Name        = "terraform-state-lock"
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "oidc_terraform_github_actions_demo"
    Owner       = "Barigbue Nbira"
}
}