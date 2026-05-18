provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    config_path = pathexpand("~/.kube/config")
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}
