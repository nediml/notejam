# AWS
# provider for talking with AWS API
provider "aws" {
  profile  = "notejam"
  region   = "${var.region}"
}

# backend on s3/dynamodb, for storing tfstate 
terraform {
  backend "s3" {
    bucket         = "notejam-tf-state"
    key            = "tf.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "notejam-tf-state"
    profile        = "notejam"
  }
}

# GITLAB
# provider for talking with Gitlab API
provider "gitlab" {
  token = "${var.gitlab_token}"
}

variable "gitlab_token" {
}



# below listed items are used mostly 
# for naming the resources in a consistent way
variable "proj_name" {
    default = "notejam"
}
variable "region" {}
data "aws_caller_identity" "current" {}

locals {
  aws_account_id = "${data.aws_caller_identity.current.account_id}"
}