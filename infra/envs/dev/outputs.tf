output "ecr_frontend_url" {
  value = module.ecr_frontend.repo_name
}

output "ecr_backend_url" {
  value = module.ecr_backend.repo_name
}
