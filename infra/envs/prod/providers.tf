terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# Fuer ACM Zertifikate fuer CloudFront
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
