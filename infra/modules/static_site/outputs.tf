output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "bucket_name" {
  value = aws_s3_bucket.site.bucket
}
