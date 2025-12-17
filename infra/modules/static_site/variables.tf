variable "domain_name" {
  type        = string
  description = "Primary domain name (e.g. canyildiz.de)"
}

variable "hosted_zone_name" {
  type        = string
  description = "Route53 hosted zone name (e.g. canyildiz.de)"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for website content"
}
variable "enable_acm_validation" {
  type    = bool
  default = false
}
