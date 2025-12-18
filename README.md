# AWS Secure Static Website (Terraform)

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6-623CE4?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonwebservices)
![CI](https://github.com/Cann65/aws-secure-static-website-terraform/actions/workflows/terraform-ci.yml/badge.svg)

Secure AWS hosting for static build artifacts (React/Vite/Next export, etc.) delivered via CloudFront and a private S3 origin, with DNS in Route 53 and TLS from ACM (us-east-1). The repository includes an evidence pack (screenshots) demonstrating identity, permissions, Terraform idempotency, audit logging, and deployed resources.

---

## Scope and Capabilities
- CloudFront + S3 + Route 53 + ACM working together
- Remote Terraform state in S3 (optional DynamoDB locking)
- Reusable module with parameterized inputs (domain, bucket, optional WAF, optional ACM DNS validation)
- Private S3 origin, CloudFront Origin Access Control (OAC), HTTPS-only, and least-privilege Terraform access via IAM Identity Center (SSO)
- Auditability through CloudTrail (evidence provided)

---

## Architecture
```mermaid
flowchart LR
    U[Users] -->|HTTPS| CF[CloudFront<br/>OAC + caching]
    CF -->|OAC| S3[(S3 bucket<br/>private)]
    ACM[ACM certificate<br/>us-east-1] --> CF
    R53[Route 53] -->|Alias A| CF
```
S3 remains private; CloudFront is the only reader.

---

## Repository Structure
```
.github/workflows/terraform-ci.yml   # CI: fmt/init/validate
infra/
  modules/static_site/               # Module: S3, CloudFront, ACM, Route 53
  envs/prod/                         # Example environment + remote backend config
  docs/evidence/                     # Evidence screenshots (redact before sharing)
README.md
```

---

## Prerequisites
- Terraform >= 1.6
- AWS provider >= 5.x
- Existing Route 53 hosted zone for your domain
- Remote backend bucket for Terraform state (optional DynamoDB lock table)
- AWS credentials configured locally (recommended: AWS SSO / IAM Identity Center)

---

## Configuration
Defaults in `infra/envs/prod/variables.tf` (override via `-var` or `*.tfvars`):

| Variable                | Description                              | Default        | Example        |
| ----------------------- | ---------------------------------------- | -------------- | -------------- |
| domain_name             | Website domain                           | canyildiz.de   | example.com    |
| hosted_zone_name        | Route 53 hosted zone                     | canyildiz.de   | example.com    |
| bucket_name             | S3 bucket for static assets              | canyildiz.de   | example.com    |
| enable_acm_validation   | Auto-create DNS validation records       | false          | true           |
| web_acl_id              | Optional WAFv2 WebACL ARN (CLOUDFRONT)   | null           | arn:aws:wafv2:... |

ACM validation: if `enable_acm_validation = true`, Terraform creates DNS validation records in Route 53 and runs certificate validation.
WAF: `web_acl_id` must be a WAFv2 WebACL ARN with Scope CLOUDFRONT (commonly in us-east-1).

---

## Deployment (prod example)

Windows / PowerShell (AWS SSO):
```powershell
aws sso login --profile <your-sso-profile>
$env:AWS_PROFILE = "<your-sso-profile>"
$env:AWS_SDK_LOAD_CONFIG = "1"
cd infra/envs/prod
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

Linux/macOS / Bash (AWS SSO):
```bash
aws sso login --profile <your-sso-profile>
export AWS_PROFILE="<your-sso-profile>"
cd infra/envs/prod
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

Outputs typically include:
- cloudfront_domain: CloudFront distribution domain
- bucket_name: S3 bucket for site assets

---

## Upload Static Content (example)
```bash
npm run build
aws s3 sync ./build s3://<your-bucket-name>/ --delete
```
Optional caching pattern:
```bash
aws s3 sync ./build s3://<your-bucket-name>/ --delete \
  --exclude "index.html" \
  --cache-control "public,max-age=31536000,immutable"
aws s3 cp ./build/index.html s3://<your-bucket-name>/index.html \
  --cache-control "public,max-age=60"
```
CloudFront invalidation if required:
```bash
aws cloudfront create-invalidation --distribution-id <dist-id> --paths "/*"
```

---

## Security Decisions

| Decision                        | Rationale                                                      |
| --------------------------------| -------------------------------------------------------------- |
| Private S3 + CloudFront OAC     | Only CloudFront can read; no public S3 access                  |
| HTTPS-only & modern TLS         | Enforces encrypted transport; reduces downgrade risk           |
| Least-privilege Terraform role  | Uses scoped SSO role instead of broad admin                    |
| Evidence over claims            | Screenshots for identity, policy scope, audit logs, resources  |

---

## Evidence Pack
Files in `infra/docs/evidence/`. Redact account IDs, hosted zone IDs, email addresses, source IPs, access key IDs, request/event IDs before sharing.

| #  | File                                      | Purpose                                               |
| -- | ----------------------------------------- | ----------------------------------------------------- |
| 1  | 01-cli-sts-terraformdeployer.png          | CLI session uses TerraformDeployer assumed role (SSO) |
| 2  | 01-identity-center-assignments.png        | IAM Identity Center assignments / permission sets     |
| 3  | 02a-terraformdeployer-general.png         | TerraformDeployer permission set overview             |
| 4  | 02b-terraformdeployer-inline-policy.png   | Inline policy shows scoped permissions                |
| 5  | 02-terraform-plan-no-changes.png          | Terraform plan shows no drift                         |
| 6  | 03-cloudtrail-assumerole.png              | CloudTrail logs SSO federation / AssumeRoleWithSAML   |
| 7  | 04-cloudtrail-terraform-action.png        | CloudTrail logs Terraform-triggered API activity      |
| 8  | 05a-s3-buckets.png                        | S3 buckets exist (site bucket + tfstate bucket)       |
| 9  | 05b-cloudfront-distribution.png           | CloudFront distribution deployed                      |
| 10 | 05c-acm-certificate-issued.png            | ACM certificate issued in us-east-1                   |
| 11 | 05d-route53-hosted-zone.png               | Route 53 records point to CloudFront                  |

---

## Continuous Integration
Workflow: `.github/workflows/terraform-ci.yml` (runs on push/PR to main/master)
- terraform fmt -check -recursive
- terraform init -backend=false
- terraform validate

---

## Roadmap
- Add CloudFront/S3 access logging and query via Athena
- Add AWS WAF baseline rules (rate limiting + managed rules)
- Add cost guardrails (Budgets + alarms)
- Add security scanning (tflint, tfsec, checkov)
- Add terraform.tfvars.example for quicker onboarding
