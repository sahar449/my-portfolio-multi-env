vpc_cidr             = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.3.0/24", "10.10.4.0/24"]
availability_zones   = ["us-west-2a", "us-west-2b"]
name_prefix          = "eksdemo-mgmt"
cluster_name         = "eksdemo-mgmt-cluster"
