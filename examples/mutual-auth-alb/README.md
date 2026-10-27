# Mutual TLS ALB Example

This example creates an Application Load Balancer that requires client certificates (mTLS):

- Trust store created from a CA bundle stored in S3
- Optional certificate revocation list (CRL) attached to the trust store
- HTTPS listener in `verify` mode referencing the trust store by key (`trust_store_key`)
- Trusted CA names advertised to clients during the TLS handshake
- Client certificate subject, issuer and validity forwarded to targets with custom header names
- HTTP to HTTPS redirect

## Prerequisites

Upload the PEM CA bundle (and, optionally, a PEM CRL) to an S3 bucket the load balancer can read:

```bash
aws s3 cp ca-bundle.pem s3://my-trust-store-bucket/ca/ca-bundle.pem
aws s3 cp crl.pem s3://my-trust-store-bucket/crl/crl.pem
```

## Usage

```bash
terraform init
terraform plan \
  -var="vpc_id=vpc-xxx" \
  -var='public_subnets=["subnet-xxx","subnet-yyy"]' \
  -var="certificate_arn=arn:aws:acm:us-east-1:123456789012:certificate/xxx" \
  -var="trust_store_bucket=my-trust-store-bucket" \
  -var="crl_s3_key=crl/crl.pem"
terraform apply
```

Test with a client certificate signed by the trusted CA:

```bash
curl --cert client.pem --key client.key https://<lb_dns_name>/
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | ~> 6.28 |
