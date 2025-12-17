variable "domain_name" {
  default = "canyildiz.de"
}

variable "hosted_zone_name" {
  default = "canyildiz.de"
}

variable "bucket_name" {
  default = "canyildiz.de"
}

variable "enable_acm_validation" {
  type    = bool
  default = false
}
