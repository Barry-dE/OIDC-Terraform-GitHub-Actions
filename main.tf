
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

 
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}


module "vpc" {
  source = "./modules/vpc"
 network_config = var.network_config
}