
variable "oidc_provider_arn" {
  description = "OIDC ARN of your EKS account"
}

variable "oidc_provider_url" {
  description = "OIDC URL of your EKS account"
}

variable "name_prefix" {
  description = "Environment prefix for unique IAM resource names"
  type        = string
}

