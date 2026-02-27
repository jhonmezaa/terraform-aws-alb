# Complete ALB Example

This example creates a production-ready Application Load Balancer with all features:

- HTTPS listener with ACM certificate and TLS 1.3
- HTTP to HTTPS redirect
- Weighted target groups (90/10 canary deployment)
- Path-based routing rules (API, health check)
- CORS and security response headers (HSTS, X-Frame-Options, etc.)
- Route53 A and AAAA alias records
- Managed security group
- Cookie-based stickiness

## Usage

```bash
terraform init
terraform plan \
  -var="vpc_id=vpc-xxx" \
  -var='public_subnets=["subnet-xxx","subnet-yyy"]' \
  -var="certificate_arn=arn:aws:acm:us-east-1:123456789012:certificate/xxx" \
  -var="route53_zone_id=Z0123456789" \
  -var="domain_name=app.example.com"
terraform apply
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.46 |
