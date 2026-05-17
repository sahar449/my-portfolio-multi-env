vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.3.0/24", "10.2.4.0/24"]
availability_zones   = ["us-west-2a", "us-west-2b"]

name_prefix  = "eksdemo-prod"
cluster_name = "eksdemo-prod-cluster"
region       = "us-west-2"

# RDS config
DB_NAME     = "mydb_prod"
DB_USER     = "db_user"
secret_name = "rds-creds-prod"
