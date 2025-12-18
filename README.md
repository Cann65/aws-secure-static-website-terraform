# AWS Secure Static Website (Terraform)

A concise AWS infrastructure project that delivers a **secure-by-default static website** with **least-privilege Terraform access**.

- **Origin:** Private S3 bucket (no public website hosting)
- **CDN:** CloudFront with **Origin Access Control (OAC)**
- **TLS:** HTTPS-only via ACM certificate (must be in `us-east-1` for CloudFront)
- **DNS:** Route 53 alias records
- **IaC:** Terraform
- **Access model:** AWS IAM Identity Center (SSO) with a scoped **TerraformDeployer** permission set

This repository is meant to be understood in minutes and verified via screenshots.

---

## What this project demonstrates

### Security & platform fundamentals
- Private S3; CloudFront is the only reader via OAC.
- HTTPS-only delivery with a modern TLS policy.
- Least privilege for IaC (dedicated SSO role instead of broad admin).
- Auditable changes (CloudTrail evidence included).

### Practical AWS building blocks
- S3 + CloudFront + ACM + Route53 working together.
- Remote Terraform state in S3 (optional DynamoDB lock).
- Parameterized module inputs (domain, bucket, optional WAF, optional ACM DNS validation).

> Note: The website content can be any static build (React, etc.). After `npm run build`, the output can be synced to S3 and served via CloudFront.

---

## Repository structure
- `infra/modules/static_site` - Reusable Terraform module (S3 bucket, CloudFront distribution, ACM certificate, Route53 records).
- `infra/envs/prod` - Example prod environment consuming the module, including remote backend config.
- `infra/docs/evidence` - Screenshots proving the deployment and access model.

---

## Architecture
```
Users
  |
  v
CloudFront (HTTPS, caching, OAC)
  |
  v
S3 bucket (private, no public access)

ACM (us-east-1) -> CloudFront certificate
Route53 -> Alias A records -> CloudFront
```

---

## Prerequisites
- Terraform `>= 1.6`
- AWS provider `>= 5.x`
- Existing Route53 hosted zone for your domain
- Remote backend bucket for Terraform state (plus optional DynamoDB for locking)
- AWS credentials configured locally (recommended: AWS SSO / IAM Identity Center)

---

## Configuration
Defaults live in `infra/envs/prod/variables.tf` (override via `-var` or `*.tfvars`):

- `domain_name` (e.g., `example.com`)
- `hosted_zone_name` (e.g., `example.com`)
- `bucket_name` (e.g., `example.com`)
- `enable_acm_validation` (bool, default `false`)
- `web_acl_id` (string, default `null`)

### About ACM validation
If `enable_acm_validation=true`, Terraform creates DNS validation records in Route 53 and runs `aws_acm_certificate_validation`.

### About WAF (optional)
If you attach a WAF, `web_acl_id` must be a **WAFv2 WebACL ARN with Scope `CLOUDFRONT`** (commonly managed in `us-east-1`).

---

## Deploy (prod example)
From the repository root:
```powershell
cd infra/envs/prod
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

After apply, Terraform outputs typically include:
- `cloudfront_domain`: CloudFront distribution domain
- `bucket_name`: S3 bucket for site assets

### Upload website content
Adjust paths/bucket as needed:
```bash
aws s3 sync ./dist s3://<your-bucket-name>/ --delete
```

---

## Security decisions (why)
- **Private S3 + CloudFront OAC:** Prevents direct public reads; CloudFront is the only allowed reader.
- **HTTPS-only & modern TLS:** Reduces downgrade risk; enforces encrypted transport.
- **Least-privilege Terraform role:** Uses an SSO role (TerraformDeployer) with scoped permissions instead of broad admin.
- **Evidence over claims:** Screenshots for identity, permissions, CloudTrail, and deployed resources.

---

## Evidence (screenshots)
All images live in `infra/docs/evidence/`:

### CLI identity and role
- ![STS caller identity (TerraformDeployer)](infra/docs/evidence/01-cli-sts-terraformdeployer.png)

### IAM Identity Center / Permission sets
- ![Identity Center assignments](infra/docs/evidence/01-identity-center-assignments.png)
- ![TerraformDeployer permission set - general](infra/docs/evidence/02a-terraformdeployer-general.png)
- ![TerraformDeployer permission set - inline policy](infra/docs/evidence/02b-terraformdeployer-inline-policy.png)

### Terraform proof
- ![Terraform plan - no changes](infra/docs/evidence/02-terraform-plan-no-changes.png)

### CloudTrail proof (auditability)
- ![CloudTrail AssumeRole event](infra/docs/evidence/03-cloudtrail-assumerole.png)
- ![CloudTrail Terraform action](infra/docs/evidence/04-cloudtrail-terraform-action.png)

### AWS resources proof
- ![S3 buckets](infra/docs/evidence/05a-s3-buckets.png)
- ![CloudFront distribution](infra/docs/evidence/05b-cloudfront-distribution.png)
- ![ACM certificate issued](infra/docs/evidence/05c-acm-certificate-issued.png)
- ![Route53 hosted zone and records](infra/docs/evidence/05d-route53-hosted-zone.png)

> If you share this repo publicly, consider blurring account IDs, hosted zone IDs, IPs, or emails in the screenshots.

---

## Roadmap / next improvements
- Add baseline AWS WAF rules (rate limiting + managed rules).
- Enable access logging (CloudFront and/or S3) and query via Athena.
- Add cost guardrails (budgets + alarms).
- Add CI for `terraform fmt/validate/plan` on PRs.
