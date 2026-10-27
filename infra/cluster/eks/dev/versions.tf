terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }

  # O backend não aceita variáveis: edite os valores abaixo.
  backend "s3" {
    bucket       = "tfstate-eks-167871570924"
    key          = "eks-platform/01-infra.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}
