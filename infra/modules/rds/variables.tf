### variables rds ###
variable "DB_NAME" {}
variable "DB_USER" {}
variable "vpc_id" {}
variable "secret_name" {}
variable "cidr_blocks" {}
variable "private_subnets" {
  type = list(string)
}
variable "name_prefix" {
  description = "Environment prefix for unique resource names (dev, staging, prod)"
  type        = string
}
