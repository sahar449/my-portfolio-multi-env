terraform {
  backend "s3" {
    bucket         = "eksdemo-terraform-state"
    key            = "eksdemo/ecr/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
