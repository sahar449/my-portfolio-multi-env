variable "vpc_cidr" {}
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "availability_zones" { type = list(string) }
variable "name_prefix" {}
variable "cluster_name" {}
variable "region" {}
variable "DB_NAME" {}
variable "DB_USER" {}
variable "secret_name" {}

# IAM username granted EKS cluster-admin (passed from CI via TF_VAR_admin_username).
variable "admin_username" {
  type    = string
  default = ""
}
