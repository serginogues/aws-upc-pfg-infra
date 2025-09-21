terraform {
  required_version = ">= 1.1.5"

  backend "s3" {
    bucket         = "aws-upc-pfg-infra-tfstate-bucket-marc10010" # Project B's OWN state bucket
    key            = "aws-upc-pfg-infra/terraform.tfstate"
    region         = "us-east-1"  # or your preferred region
    encrypt        = true
    use_lockfile   = true  # Optional but recommended for state locking
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}



data "terraform_remote_state" "aws_upc_pfg_tfstate" {
  backend = "s3"
  config = {
    bucket = "aws-upc-pfg-tfstate-bucket-${var.account_name}"  # Producer project's state bucket
    key    = "aws-upc-pfg-code/terraform.tfstate"
    region = "us-east-1"
  }
}
