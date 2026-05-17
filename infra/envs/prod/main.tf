### prod environment — full stack, separate from dev and staging ###

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

# ─────────────────────────────────────────────────────────────────
# Cluster components — installed once via Terraform, not per-deploy
# ─────────────────────────────────────────────────────────────────

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.8.3"

  values = [<<-EOT
    clusterName: ${var.cluster_name}
    region: ${var.region}
    vpcId: ${module.vpc.vpc_id}
    serviceAccount:
      create: true
      name: aws-load-balancer-controller
      annotations:
        eks.amazonaws.com/role-arn: ${module.iam.alb_controller_role_arn}
  EOT
  ]

  wait       = true
  timeout    = 300
  depends_on = [module.eks, module.iam]
}

resource "aws_eks_addon" "external_dns" {
  cluster_name             = var.cluster_name
  addon_name               = "external-dns"
  service_account_role_arn = module.iam.external_dns_role_arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on               = [module.eks, module.iam]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.8.23"
  namespace        = "argocd"
  create_namespace = true

  values = [file("${path.module}/../../../ArgoCD/argocd-server-values.yaml")]

  wait       = true
  timeout    = 600
  depends_on = [module.eks, helm_release.alb_controller, helm_release.external_dns]
}
