### dev environment — ECR + VPC ###

module "ecr_frontend" {
  source    = "../../modules/ecr"
  repo_name = "frontend-dev"
}

module "ecr_backend" {
  source    = "../../modules/ecr"
  repo_name = "backend-dev"
}

module "vpc" {
  source               = "../../modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  name_prefix          = var.name_prefix
}
