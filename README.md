# terraform-aws-alb

Terraform module to create AWS Elastic Load Balancers (ALB, NLB, GWLB) with listeners, target groups, security groups, Route53 records, and WAF integration.

## Features

### Load Balancer Types
- **Application Load Balancer (ALB)** - Layer 7 HTTP/HTTPS routing
- **Network Load Balancer (NLB)** - Layer 4 TCP/UDP/TLS routing
- **Gateway Load Balancer (GWLB)** - GENEVE protocol for network appliances

### Listener Capabilities
- **7 default action types**: forward, weighted forward, redirect, fixed response, authenticate Cognito, authenticate OIDC, JWT validation (planned)
- **Mutual TLS authentication** with trust store support
- **Additional SSL certificates** per listener
- **CORS headers**: Allow-Origin, Allow-Methods, Allow-Headers, Expose-Headers, Max-Age, Allow-Credentials
- **Security headers**: Content-Security-Policy, Strict-Transport-Security (HSTS), X-Content-Type-Options, X-Frame-Options
- **mTLS request headers**: Client certificate, issuer, leaf, serial number, subject, validity, TLS cipher suite, TLS version

### Listener Rules
- **6 condition types**: host header, path pattern, HTTP header, HTTP request method, query string, source IP
- **All action types** available in rules (forward, weighted forward, redirect, fixed response, authenticate)
- **Priority-based** routing

### Target Groups
- **4 target types**: instance, ip, lambda, alb
- **Health checks**: configurable interval, threshold, matcher, path, port, protocol, timeout
- **5 stickiness types**: lb_cookie, app_cookie, source_ip, source_ip_dest_ip, source_ip_dest_ip_proto
- **3 load balancing algorithms**: round_robin, least_outstanding_requests, weighted_random
- **Protocol versions**: HTTP/1.1, HTTP/2, gRPC
- **Target failover** (NLB): configurable deregistration and unhealthy behavior
- **Target group health**: DNS failover thresholds and unhealthy state routing
- **Lambda integration**: automatic permission creation, multi-value headers, qualifier support
- **Proxy protocol v2** support

### Security
- **Managed security group** with ingress/egress rules (using `aws_vpc_security_group_*_rule`)
- **WAFv2 Web ACL** association
- **Deletion protection** (enabled by default)
- **Invalid header dropping** (enabled by default)
- **Desync mitigation**: monitor, defensive, strictest modes

### Networking
- **Cross-zone load balancing** (enabled by default)
- **Dual-stack IP** support (IPv4 + IPv6)
- **Subnet mapping** with Elastic IP allocation
- **Zonal shift** support
- **Host header preservation**
- **XFF header processing**: append, preserve, remove

### Logging
- **Access logs** to S3
- **Connection logs** to S3
- **Minimum capacity** pre-provisioning

### DNS Integration
- **Route53 alias records**: A, AAAA, CNAME
- **Target health evaluation** per record

## Naming Convention

Resources follow the standard naming pattern:

```
{region_prefix}-{resource_type}-{account_name}-{project_name}
```

Examples:
- ALB: `ause1-alb-prod-myapp`
- NLB: `ause1-nlb-prod-myapp`
- Target Group: `ause1-tg-prod-myapp-web`
- Security Group: `ause1-sg-alb-prod-myapp`

Region prefixes are auto-detected (e.g., `us-east-1` -> `ause1`).

## Usage

### Basic ALB

```hcl
module "alb" {
  source = "./terraform-aws-alb/alb"

  account_name = "prod"
  project_name = "myapp"
  vpc_id       = "vpc-xxx"
  subnets      = ["subnet-xxx", "subnet-yyy"]

  enable_deletion_protection = false

  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  target_groups = {
    web = {
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"

      health_check = {
        path     = "/health"
        protocol = "HTTP"
        matcher  = "200"
      }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward  = { target_group_key = "web" }
    }
  }
}
```

### HTTPS with HTTP Redirect

```hcl
module "alb" {
  source = "./terraform-aws-alb/alb"

  account_name = "prod"
  project_name = "myapp"
  vpc_id       = "vpc-xxx"
  subnets      = ["subnet-xxx", "subnet-yyy"]

  target_groups = {
    web = {
      port     = 80
      protocol = "HTTP"
      health_check = { path = "/health" }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:..."
      forward         = { target_group_key = "web" }
    }
  }
}
```

### NLB

```hcl
module "nlb" {
  source = "./terraform-aws-alb/alb"

  account_name       = "prod"
  project_name       = "services"
  load_balancer_type = "network"
  vpc_id             = "vpc-xxx"
  subnets            = ["subnet-xxx", "subnet-yyy"]

  create_security_group = false

  target_groups = {
    tcp = {
      port        = 80
      protocol    = "TCP"
      target_type = "instance"
      health_check = { protocol = "TCP" }
    }
  }

  listeners = {
    tcp = {
      port     = 80
      protocol = "TCP"
      forward  = { target_group_key = "tcp" }
    }
  }
}
```

## Examples

- [Basic ALB](examples/basic-alb/) - Simple HTTP ALB
- [Complete ALB](examples/complete-alb/) - Production ALB with HTTPS, canary, routing rules, CORS, Route53
- [NLB](examples/nlb/) - Network Load Balancer with TCP and TLS

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | >= 5.46 |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `account_name` | Account name for resource naming | `string` | - |
| `project_name` | Project name for resource naming | `string` | - |
| `create` | Controls if resources should be created | `bool` | `true` |
| `name` | Load balancer name (auto-generated if null) | `string` | `null` |
| `load_balancer_type` | Type: application, network, gateway | `string` | `"application"` |
| `internal` | Internal load balancer | `bool` | `false` |
| `subnets` | Subnet IDs | `list(string)` | `null` |
| `vpc_id` | VPC ID for target groups and security group | `string` | `null` |
| `listeners` | Map of listener configurations | `any` | `{}` |
| `target_groups` | Map of target group configurations | `any` | `{}` |
| `enable_deletion_protection` | Enable deletion protection | `bool` | `true` |
| `enable_cross_zone_load_balancing` | Enable cross-zone load balancing | `bool` | `true` |
| `create_security_group` | Create managed security group | `bool` | `true` |
| `security_group_ingress_rules` | Ingress rules for managed SG | `any` | `{}` |
| `security_group_egress_rules` | Egress rules for managed SG | `any` | `{}` |
| `route53_records` | Route53 alias records | `any` | `{}` |
| `associate_web_acl` | Associate WAFv2 Web ACL | `bool` | `false` |
| `web_acl_arn` | WAFv2 Web ACL ARN | `string` | `null` |
| `tags` | Additional tags | `map(string)` | `{}` |

See [10-variables.tf](alb/10-variables.tf) for the complete list of variables.

## Outputs

| Name | Description |
|------|-------------|
| `lb_id` | Load balancer ID |
| `lb_arn` | Load balancer ARN |
| `lb_arn_suffix` | ARN suffix (for CloudWatch Metrics) |
| `lb_dns_name` | DNS name |
| `lb_zone_id` | Hosted zone ID (for Route53) |
| `lb_name` | Load balancer name |
| `listeners` | Map of all listeners |
| `listener_rules` | Map of all listener rules |
| `target_groups` | Map of all target groups |
| `security_group_id` | Managed security group ID |
| `security_group_arn` | Managed security group ARN |
| `route53_records` | Map of Route53 records |

## Module Structure

```
terraform-aws-alb/
├── alb/
│   ├── 0-versions.tf              # Provider version constraints
│   ├── 0-data.tf                  # Data sources (region, identity, partition)
│   ├── 0-locals.tf                # Locals (region prefix, naming, flattening)
│   ├── 1-alb.tf                   # Load balancer resource
│   ├── 2-listeners.tf             # Listeners with all action types
│   ├── 3-listener-rules.tf        # Listener rules with conditions
│   ├── 4-listener-certificates.tf # Additional SSL certificates
│   ├── 5-target-groups.tf         # Target groups
│   ├── 6-target-attachments.tf    # Attachments and Lambda permissions
│   ├── 7-security-group.tf        # Managed security group
│   ├── 8-route53.tf               # Route53 alias records
│   ├── 9-waf.tf                   # WAFv2 association
│   ├── 10-variables.tf            # Input variables
│   └── 11-outputs.tf              # Output values
├── examples/
│   ├── basic-alb/
│   ├── complete-alb/
│   └── nlb/
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## License

MIT
