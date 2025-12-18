AWS Secure Static Website - Terraform
=====================================

Dieses Projekt stellt eine sichere, statische Website auf AWS bereit. Statische Dateien liegen in S3 und werden nur ueber CloudFront mit TLS ausgeliefert. Zertifikate kommen aus ACM (us-east-1), DNS wird mit Route53 verwaltet.

Verzeichnisstruktur
-------------------
- `infra/modules/static_site`: Modul mit S3-Bucket, CloudFront, ACM-Zertifikat und Route53-Records.
- `infra/envs/prod`: Produktiv-Stack, der das Modul konsumiert und das Remote-Backend konfiguriert.

Architektur (Modul `static_site`)
---------------------------------
- S3-Bucket fuer Website-Inhalte (`aws_s3_bucket.site`) mit Public-Access-Block; Zugriff nur via CloudFront.
- CloudFront-Distribution mit Origin Access Control (OAC), HTTPS-Redirect, Default Root `index.html`; Origin-Domain wird aus dem Bucket abgeleitet (keine Hardcodes), 403/404 werden auf `index.html` gemappt (SPA-tauglich).
- ACM-Zertifikat in `us-east-1` fuer `domain_name` und `www.domain_name`; DNS-Validierung optional automatisierbar.
- Route53 A-Records fuer Root- und `www`-Domain zeigen als Alias auf CloudFront.
- Bucket-Policy erlaubt nur CloudFront als Principal (`AWS:SourceArn`-Bedingung).

Voraussetzungen
---------------
- Terraform >= 1.6 (siehe `infra/envs/prod/providers.tf`).
- AWS Provider >= 5.0.
- AWS-Konto mit bestehender Route53-Hosted-Zone fuer die Ziel-Domain.
- S3-Bucket fuer das Terraform-Backend (siehe unten).
- AWS-Credentials lokal konfiguriert (z.B. `AWS_PROFILE`).

Remote Backend
--------------
Konfiguration in `infra/envs/prod/backend.tf`:
- Bucket: `tfstate-canyildiz-prod`
- Key: `secure-website/prod/terraform.tfstate`
- Region: `eu-central-1`

Lege den Bucket (und ggf. ein DynamoDB-Lock, falls du kein Lockfile nutzen willst) an, bevor du `terraform init` ausfuehrst.

Konfiguration (prod)
--------------------
Standardwerte in `infra/envs/prod/variables.tf`:
- `domain_name` / `hosted_zone_name`: `canyildiz.de`
- `bucket_name`: `canyildiz.de`
- `enable_acm_validation`: `false` (siehe unten)
- `web_acl_id`: `null` (kein WAF angehaengt; per ARN optional aktivierbar)

Anpassungen kannst du per `-var` oder `*.tfvars` uebergeben.

Hinweis zu ACM-Validierung
--------------------------
Setze `enable_acm_validation=true`, wenn die DNS-Validierung automatisch erfolgen soll. Dann werden die noetigen CNAME-Records in Route53 angelegt und `aws_acm_certificate_validation` ausgefuehrt.

Deployment
----------
Aus `infra/envs/prod`:
```powershell
cd infra/envs/prod
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

Outputs nach `apply`:
- `cloudfront_domain`: CloudFront-Domain.
- `bucket_name`: S3-Bucket fuer deine statischen Dateien.

Website-Inhalte hochladen
-------------------------
Beispiel (Bucket ggf. anpassen):
```bash
aws s3 sync ./dist s3://canyildiz.de/ --delete
```

Sicherheit & Betrieb
--------------------
- Direkter S3-Public-Zugriff ist blockiert; Auslieferung nur ueber CloudFront-OAC.
- CloudFront TLS-Minimum: `TLSv1.3_2025`.
- Optionaler WAF: setze `web_acl_id` auf die ARN deiner WAFv2-WebACL mit Scope `CLOUDFRONT` (typisch in us-east-1), sonst bleibt kein WAF angehaengt.
- 403/404 liefern `index.html` (SPA geeignet).

Behoben / Verbesserungen
------------------------
- Origin-Domain wird aus dem Bucket abgeleitet (keine Hardcodes).
- Origin-ID und OAC-Name sind generisch pro Domain.
- WAF-Anbindung ist optional via `web_acl_id`.
