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

  description = "Whether to create DNS validation records and validate the ACM certificate automatically."
}

variable "web_acl_id" {
  type        = string
  default     = null
  description = "Optional WAF WebACL ARN to attach to the CloudFront distribution."
}
