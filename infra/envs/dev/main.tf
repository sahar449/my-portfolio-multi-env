### dev environment — ECR + VPC (no cluster, no RDS) ###

module "ecr_frontend" {
  source    = "../../modules/ecr"
  repo_name = "frontend"
}

module "ecr_backend" {
  source    = "../../modules/ecr"
  repo_name = "backend"
}

module "vpc" {
  source               = "../../modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  name_prefix          = var.name_prefix
}
