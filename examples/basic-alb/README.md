# Basic ALB Example

This example creates a simple internet-facing Application Load Balancer with:

- HTTP listener on port 80
- Target group for instances with health checks
- Managed security group allowing HTTP traffic

## Usage

```bash
terraform init
terraform plan -var="vpc_id=vpc-xxx" -var='public_subnets=["subnet-xxx","subnet-yyy"]'
terraform apply
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.46 |
