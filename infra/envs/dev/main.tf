### dev environment — ECR only (CI builds and pushes images, no running app) ###

module "ecr_frontend" {
  source    = "../../modules/ecr"
  repo_name = "frontend"
}

module "ecr_backend" {
  source    = "../../modules/ecr"
  repo_name = "backend"
}
