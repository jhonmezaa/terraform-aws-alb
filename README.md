# terraform-aws-alb

Terraform module to create AWS Elastic Load Balancers (ALB, NLB, GWLB) with listeners, target groups, security groups, Route53 records, and WAF integration.

## Features

### Load Balancer Types

- **Application Load Balancer (ALB)** - Layer 7 HTTP/HTTPS routing
- **Network Load Balancer (NLB)** - Layer 4 TCP/UDP/TLS routing
- **Gateway Load Balancer (GWLB)** - GENEVE protocol for network appliances

### Listener Capabilities

- **7 default action types**: forward, weighted forward, redirect, fixed response, authenticate Cognito, authenticate OIDC, JWT validation
- **Mutual TLS authentication** with module-managed trust stores (`trust_store_key`) or external trust store ARNs, CA name advertising and certificate expiry override
- **Additional SSL certificates** per listener
- **CORS headers**: Allow-Origin, Allow-Methods, Allow-Headers, Expose-Headers, Max-Age, Allow-Credentials
- **Security headers**: Content-Security-Policy, Strict-Transport-Security (HSTS), X-Content-Type-Options, X-Frame-Options
- **mTLS request headers**: Client certificate, issuer, leaf, serial number, subject, validity, TLS cipher suite, TLS version
- Header attributes are only sent for protocols that support them (HTTP/HTTPS response headers, HTTPS request headers)
- **GWLB listeners**: port/protocol omitted automatically for GENEVE

### Listener Rules

- **6 condition types**: host header, path pattern, HTTP header, HTTP request method, query string, source IP
- **Regex conditions**: `regex_values` for host header, path pattern and HTTP header
- **Transforms**: host header rewrite and URL rewrite
- **All action types** available in rules (forward, weighted forward, redirect, fixed response, authenticate, JWT validation)
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
- **Target control port** and QUIC server ID for attachments
- **Additional attachments** for multiple targets per target group

### Security

- **Managed security group** with ingress/egress rules (using `aws_vpc_security_group_*_rule`); optional `name_prefix` mode
- **NLB security groups**: user-provided, or managed via `create_network_lb_security_group` (opt-in)
- **Trust stores** and **revocation lists (CRLs)** for mTLS
- **WAFv2 Web ACL** association
- **Deletion protection** (enabled by default)
- **Invalid header dropping** (enabled by default)
- **Desync mitigation**: monitor, defensive, strictest modes

### Networking

- **Cross-zone load balancing** (enabled by default)
- **Dual-stack IP** support (IPv4 + IPv6)
- **Subnet mapping** with Elastic IP allocation
- **Zonal shift** support
- **IPAM pools** for IPv4 addresses
- **NLB source NAT**: secondary IPs per subnet and IPv6 prefix
- **Per-resource region** (`region`, AWS provider v6)
- **Host header preservation**
- **XFF header processing**: append, preserve, remove

### Logging

- **Access logs** to S3
- **Connection logs** to S3
- **Health check logs** to S3 (ALB)
- **Minimum capacity** pre-provisioning

### DNS Integration

- **Route53 alias records**: A, AAAA (dualstack), CNAME
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

- Trust Store: `ause1-ts-prod-myapp-clients`

Region prefixes are auto-detected from `region` or the provider region (e.g., `us-east-1` -> `ause1`), or set explicitly with `region_prefix`. Set `use_region_prefix = false` to omit it (`alb-prod-myapp`); in that case the security group is named `alb-sg-prod-myapp`, since AWS does not allow security group names starting with `sg-`.

Load balancer, target group and trust store names are truncated to 32 characters (AWS limit). Every name can be overridden explicitly (`name`, `security_group_name`, `target_groups.<key>.name`, `trust_stores.<key>.name`).

### Tags

All resources get `Name` and `ManagedBy = "Terraform"` tags, merged with `tags_common` and resource-specific tags. `tags` is still supported for backward compatibility and is merged on top of `tags_common`.

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

### Mutual TLS

```hcl
module "alb" {
  source = "./terraform-aws-alb/alb"

  account_name = "prod"
  project_name = "myapp"
  vpc_id       = "vpc-xxx"
  subnets      = ["subnet-xxx", "subnet-yyy"]

  trust_stores = {
    clients = {
      ca_certificates_bundle_s3_bucket = "my-trust-store-bucket"
      ca_certificates_bundle_s3_key    = "ca/ca-bundle.pem"
      revocation_lists = {
        crl = {
          revocations_s3_bucket = "my-trust-store-bucket"
          revocations_s3_key    = "crl/crl.pem"
        }
      }
    }
  }

  target_groups = {
    app = { port = 80, protocol = "HTTP" }
  }

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = "arn:aws:acm:..."
      mutual_authentication = {
        mode                           = "verify"
        trust_store_key                = "clients"
        advertise_trust_store_ca_names = "on"
      }
      forward = { target_group_key = "app" }
    }
  }
}
```

### JWT Validation and URL Rewrite (listener rule)

```hcl
rules = {
  api = {
    priority = 100
    actions = [
      {
        type          = "jwt_validation"
        order         = 1
        issuer        = "https://auth.example.com"
        jwks_endpoint = "https://auth.example.com/.well-known/jwks.json"
      },
      { type = "forward", order = 2, target_group_key = "api" }
    ]
    conditions = [{ path_pattern = { values = ["/api/*"] } }]
    transform = {
      url-rewrite = {
        url_rewrite_config = { rewrite = { regex = "^/api/(.*)$", replace = "/$1" } }
      }
    }
  }
}
```

## Examples

- [Basic ALB](examples/basic-alb/) - Simple HTTP ALB
- [Complete ALB](examples/complete-alb/) - Production ALB with HTTPS, canary, routing rules, CORS, Route53
- [NLB](examples/nlb/) - Network Load Balancer with TCP and TLS
- [Mutual TLS ALB](examples/mutual-auth-alb/) - ALB with trust store, CRL and mTLS client certificate headers

## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 1.0  |
| aws       | ~> 6.28 |

Features added in v1.1.0 (JWT validation, rule transforms, `regex_values`, health check logs, IPAM pools, NLB secondary IPs, target control port) rely on recent provider releases; the module requires AWS provider **~> 6.28** (>= 6.28, < 7.0).

## Inputs

| Name                               | Description                                  | Type           | Default         |
| ---------------------------------- | -------------------------------------------- | -------------- | --------------- |
| `account_name`                     | Account name for resource naming             | `string`       | -               |
| `project_name`                     | Project name for resource naming             | `string`       | -               |
| `create`                           | Controls if resources should be created      | `bool`         | `true`          |
| `name`                             | Load balancer name (auto-generated if null)  | `string`       | `null`          |
| `load_balancer_type`               | Type: application, network, gateway          | `string`       | `"application"` |
| `internal`                         | Internal load balancer                       | `bool`         | `false`         |
| `subnets`                          | Subnet IDs                                   | `list(string)` | `null`          |
| `vpc_id`                           | VPC ID for target groups and security group  | `string`       | `null`          |
| `listeners`                        | Map of listener configurations               | `any`          | `{}`            |
| `target_groups`                    | Map of target group configurations           | `any`          | `{}`            |
| `enable_deletion_protection`       | Enable deletion protection                   | `bool`         | `true`          |
| `enable_cross_zone_load_balancing` | Enable cross-zone load balancing             | `bool`         | `true`          |
| `create_security_group`            | Create managed security group                | `bool`         | `true`          |
| `security_group_ingress_rules`     | Ingress rules for managed SG                 | `any`          | `{}`            |
| `security_group_egress_rules`      | Egress rules for managed SG                  | `any`          | `{}`            |
| `route53_records`                  | Route53 alias records                        | `any`          | `{}`            |
| `associate_web_acl`                | Associate WAFv2 Web ACL                      | `bool`         | `false`         |
| `web_acl_arn`                      | WAFv2 Web ACL ARN                            | `string`       | `null`          |
| `region`                           | Region for all resources (provider v6)       | `string`       | `null`          |
| `use_region_prefix`                | Include region prefix in names               | `bool`         | `true`          |
| `trust_stores`                     | Map of trust stores (mTLS) with CRLs         | `any`          | `{}`            |
| `health_check_logs`                | Health check logs configuration (ALB)        | `object`       | `null`          |
| `tags_common`                      | Common tags for all resources                | `map(string)`  | `{}`            |
| `tags`                             | Additional tags (legacy, prefer tags_common) | `map(string)`  | `{}`            |

See [10-variables.tf](alb/10-variables.tf) for the complete list of variables.

## Outputs

| Name                       | Description                               |
| -------------------------- | ----------------------------------------- |
| `lb_id`                    | Load balancer ID                          |
| `lb_arn`                   | Load balancer ARN                         |
| `lb_arn_suffix`            | ARN suffix (for CloudWatch Metrics)       |
| `lb_dns_name`              | DNS name                                  |
| `lb_zone_id`               | Hosted zone ID (for Route53)              |
| `lb_name`                  | Load balancer name                        |
| `lb_tags_all`              | All LB tags (incl. provider default_tags) |
| `listeners`                | Map of all listeners                      |
| `listener_rules`           | Map of all listener rules                 |
| `target_groups`            | Map of all target groups                  |
| `security_group_id`        | Managed security group ID                 |
| `security_group_arn`       | Managed security group ARN                |
| `security_group_name`      | Managed security group name               |
| `target_group_attachments` | Primary and additional attachments        |
| `trust_stores`             | Map of trust stores                       |
| `trust_store_arns`         | Map of trust store keys to ARNs           |
| `trust_store_revocations`  | Map of trust store revocation lists       |
| `route53_records`          | Map of Route53 records                    |

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
│   ├── 4-trust-stores.tf          # Trust stores and revocation lists (mTLS)
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
│   ├── mutual-auth-alb/
│   └── nlb/
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## License

MIT
