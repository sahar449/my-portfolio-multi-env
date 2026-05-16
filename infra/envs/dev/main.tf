### dev environment — ECR + VPC + RDS only (no cluster, ArgoCD on mgmt deploys here) ###

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

module "ssl" {
  source = "../../modules/ssl"
}

module "rds" {
  source          = "../../modules/rds"
  DB_NAME         = var.DB_NAME
  DB_USER         = var.DB_USER
  secret_name     = var.secret_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  cidr_blocks     = module.vpc.cidr_blocks
}
