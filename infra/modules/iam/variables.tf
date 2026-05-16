
variable "oidc_provider_arn" {
  description = "OIDC ARN of your EKS account"
}

variable "oidc_provider_url" {
  description = "OIDC URL of your EKS account"
}

variable "create_iam" {
  description = "Set to true to create IAM resources, false to look up existing ones (for staging/prod)"
  type        = bool
  default     = true
}
