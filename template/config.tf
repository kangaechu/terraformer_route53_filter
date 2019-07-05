terraform {
  backend "s3" {
    region = "ap-northeast-1"
    bucket = "tfstateを保存するバケット名"
    key    = "route53/@@@@@@@@/terraform.tfstate"
  }
}

