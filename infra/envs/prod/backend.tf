terraform {
  backend "s3" {
    bucket       = "tfstate-canyildiz-prod"
    key          = "secure-website/prod/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
