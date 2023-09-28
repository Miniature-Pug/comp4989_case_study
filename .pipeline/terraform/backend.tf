terraform {
  backend "s3" {
    bucket         = "bcit-local"
    key            = "comp/4989/projects/1/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock-dynamo"
  }
}
