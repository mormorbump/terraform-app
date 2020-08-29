
provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "kazuki.matsumoto"
  region                  = "ap-northeast-1"
}

terraform {
  required_version = ">= 0.12"
  backend "s3" {
    shared_credentials_file = "~/.aws/credentials"
    profile                 = "kazuki.matsumoto"
    bucket                  = "besides-terraform-back"
    key                     = "ap-northeast-1/app-stg/terraform.tfstate"
    region                  = "ap-northeast-1"
  }
}
# # sesはtokyoにはないので、別リージョンを用意
# provider "aws" {
#   alias  = "west"
#   region = "us-west-2"
# }

resource "aws_key_pair" "auth" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)
}