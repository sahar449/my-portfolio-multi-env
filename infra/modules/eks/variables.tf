### variables eks ###

variable "vpc_id" {}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "cluster_name" {}

variable "aws_admin_user" {
  description = "IAM username to grant cluster admin access"
  type        = string
}