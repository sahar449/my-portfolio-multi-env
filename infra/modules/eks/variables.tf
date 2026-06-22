### variables eks ###

variable "vpc_id" {}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "cluster_name" {}

# IAM principal ARNs granted cluster-admin via EKS access entries.
variable "admin_access_entries" {
  type    = list(string)
  default = []
}

