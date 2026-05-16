### ECR repos for staging and prod environments ###

module "ecr_frontend_staging" {
  source    = "../../modules/ecr"
  repo_name = "frontend-staging"
}

module "ecr_backend_staging" {
  source    = "../../modules/ecr"
  repo_name = "backend-staging"
}

module "ecr_frontend_prod" {
  source    = "../../modules/ecr"
  repo_name = "frontend-prod"
}

module "ecr_backend_prod" {
  source    = "../../modules/ecr"
  repo_name = "backend-prod"
}
