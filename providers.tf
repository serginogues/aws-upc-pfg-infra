terraform {
  required_version = ">= 1.1.5"

  backend "s3" {
    # Backend configuration will be provided via backend config file
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
