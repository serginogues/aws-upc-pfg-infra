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
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.region
}

# Grafana provider - will be configured dynamically

locals {
  # Read account name from environment variable, fallback to default
  account_name = try(env("TF_VAR_account_name"), "marc10010")
}

data "terraform_remote_state" "aws_upc_pfg_tfstate" {
  backend = "s3"
  config = {
    bucket = "aws-upc-pfg-tfstate-bucket-${local.account_name}"
    key    = "aws-upc-pfg-code/terraform.tfstate"
    region = "us-east-1"
  }
}
