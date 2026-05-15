vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]
availability_zones   = ["us-west-2a", "us-west-2b"]

name_prefix  = "eksdemo-staging"
cluster_name = "eksdemo-staging-cluster"
region       = "us-west-2"

# RDS config
DB_NAME     = "mydb_staging"
DB_USER     = "db_user"
secret_name = "rds-creds-staging"
