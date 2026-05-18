### staging environment — full stack ###

data "aws_caller_identity" "current" {}

module "ecr_frontend" {
  source    = "../../modules/ecr"
  repo_name = "frontend-staging"
}

module "ecr_backend" {
  source    = "../../modules/ecr"
  repo_name = "backend-staging"
}

module "vpc" {
  source               = "../../modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  name_prefix          = var.name_prefix
}

module "eks" {
  source             = "../../modules/eks"
  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
}

module "iam" {
  source            = "../../modules/iam"
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  name_prefix       = var.name_prefix
  depends_on        = [module.eks]
}

module "rds" {
  source          = "../../modules/rds"
  DB_NAME         = var.DB_NAME
  DB_USER         = var.DB_USER
  secret_name     = var.secret_name
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnet_ids
  cidr_blocks     = module.vpc.cidr_blocks
  name_prefix     = var.name_prefix
}

module "ssl" {
  source = "../../modules/ssl"
}

module "monitoring" {
  source            = "../../modules/monitoring"
  name_prefix       = var.name_prefix
  region            = var.region
  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  depends_on        = [module.eks]
}

resource "aws_eks_addon" "external_dns" {
  cluster_name                = var.cluster_name
  addon_name                  = "external-dns"
  service_account_role_arn    = module.iam.external_dns_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [module.eks, module.iam]
}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.aws_admin_user}"
  depends_on    = [module.eks]
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.admin.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}
