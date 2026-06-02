### prod environment — full stack, separate from dev and staging ###

module "ecr_frontend" {
  source    = "../../modules/ecr"
  repo_name = "frontend-prod"
}

module "ecr_backend" {
  source    = "../../modules/ecr"
  repo_name = "backend-prod"
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

# ─────────────────────────────────────────────────────────────────
# Cluster components — installed once via Terraform, not per-deploy
# ─────────────────────────────────────────────────────────────────

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.8.23"
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [file("${path.module}/../../../ArgoCD/argocd-server-values.yaml")]

  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/certificate-arn"
    value = module.ssl.ssl_cert_arn
  }

  depends_on = [module.eks, module.iam]
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.3"
  namespace  = "kube-system"
  wait       = true
  timeout    = 300

  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  set {
    name  = "region"
    value = var.region
  }
  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam.alb_controller_role_arn
  }

  depends_on = [module.eks, module.iam, helm_release.argocd]
}



