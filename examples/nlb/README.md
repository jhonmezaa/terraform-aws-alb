# NLB Example

This example creates a Network Load Balancer with:

- TCP listener on port 80
- TLS listener on port 443 with ACM certificate
- TCP target groups with health checks
- Target failover configuration
- Cross-zone load balancing enabled

## Usage

```bash
terraform init
terraform plan \
  -var="vpc_id=vpc-xxx" \
  -var='public_subnets=["subnet-xxx","subnet-yyy"]' \
  -var="certificate_arn=arn:aws:acm:us-east-1:123456789012:certificate/xxx"
terraform apply
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.46 |
