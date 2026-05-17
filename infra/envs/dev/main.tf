### dev environment — ECR repos only (no cluster, builds run on GitHub runners) ###

module "ecr_frontend" {
  source    = "../../modules/ecr"
  repo_name = "frontend-dev"
}

module "ecr_backend" {
  source    = "../../modules/ecr"
  repo_name = "backend-dev"
}
