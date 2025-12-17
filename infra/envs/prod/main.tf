module "static_site" {
  source = "../../modules/static_site"
enable_acm_validation = false

  domain_name      = var.domain_name
  hosted_zone_name = var.hosted_zone_name
  bucket_name      = var.bucket_name

  providers = {
    aws      = aws
    aws.use1 = aws.use1
  }
}
