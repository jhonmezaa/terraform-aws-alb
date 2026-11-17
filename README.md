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

Tags are built as `merge(tags_common, tags, <resource-specific tags>, { Name = <name>, ManagedBy = "Terraform" })`: `Name` and `ManagedBy` always win. `tags` is still supported for backward compatibility and is merged on top of `tags_common`.

## Usage

### Basic ALB

```hcl
module "alb" {
  source = "github.com/jhonmezaa/terraform-aws-alb//alb?ref=v1.2.0"

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
  source = "github.com/jhonmezaa/terraform-aws-alb//alb?ref=v1.2.0"

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
  source = "github.com/jhonmezaa/terraform-aws-alb//alb?ref=v1.2.0"

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
  source = "github.com/jhonmezaa/terraform-aws-alb//alb?ref=v1.2.0"

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
| terraform | >= 1.3  |
| aws       | >= 6.28 |

Features added in v1.1.0 (JWT validation, rule transforms, `regex_values`, health check logs, IPAM pools, NLB secondary IPs, target control port) rely on recent provider releases; the module requires AWS provider **>= 6.28**.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| `create` | Controls if resources should be created | `bool` | `true` | no |
| `account_name` | Account name for resource naming | `string` | n/a | yes |
| `project_name` | Project name for resource naming | `string` | n/a | yes |
| `region_prefix` | Region prefix for naming | `string` | `null` | no |
| `use_region_prefix` | Whether to include the region prefix in resource names | `bool` | `true` | no |
| `region` | AWS region where resources will be managed (provider v6 per-resource region) | `string` | `null` | no |
| `tags_common` | Common tags to apply to all resources | `map(string)` | `{}` | no |
| `tags` | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| `name` | Name of the load balancer | `string` | `null` | no |
| `lb_name_prefix` | Creates a unique load balancer name beginning with this prefix (max 6 chars) | `string` | `null` | no |
| `load_balancer_type` | Type of load balancer to create: application, network, or gateway | `string` | `"application"` | no |
| `internal` | If true, the load balancer will be internal (not internet-facing) | `bool` | `false` | no |
| `subnets` | List of subnet IDs to attach to the load balancer | `list(string)` | `null` | no |
| `subnet_mapping` | List of subnet mapping configurations with optional Elastic IP allocations | `list(object)` | `null` | no |
| `security_groups` | List of security group IDs to attach to the ALB (in addition to the managed security group) | `list(string)` | `[]` | no |
| `ip_address_type` | Type of IP addresses used by the subnets: ipv4 or dualstack | `string` | `null` | no |
| `customer_owned_ipv4_pool` | ID of the customer owned IPv4 address pool | `string` | `null` | no |
| `enable_cross_zone_load_balancing` | Enable cross-zone load balancing | `bool` | `true` | no |
| `enable_deletion_protection` | Enable deletion protection on the load balancer | `bool` | `true` | no |
| `drop_invalid_header_fields` | Whether HTTP headers with header fields that are not valid are removed by the load balancer (ALB only) | `bool` | `true` | no |
| `enable_http2` | Whether HTTP/2 is enabled on the ALB | `bool` | `null` | no |
| `idle_timeout` | Time in seconds that the connection is allowed to be idle (ALB only) | `number` | `null` | no |
| `client_keep_alive` | Client keep alive value in seconds | `number` | `null` | no |
| `preserve_host_header` | Whether the ALB should preserve the Host header in the HTTP request (ALB only) | `bool` | `null` | no |
| `xff_header_processing_mode` | How the ALB processes the X-Forwarded-For header: append, preserve, or remove (ALB only) | `string` | `null` | no |
| `enable_xff_client_port` | Whether the X-Forwarded-For header should preserve the source port (ALB only) | `bool` | `null` | no |
| `enable_tls_version_and_cipher_suite_headers` | Whether the ALB adds TLS version and cipher suite headers (ALB only) | `bool` | `null` | no |
| `desync_mitigation_mode` | How the ALB handles requests that might pose a security risk: monitor, defensive, or strictest (ALB only) | `string` | `null` | no |
| `enable_waf_fail_open` | Whether to route requests to targets if the WAF is unavailable (ALB only) | `bool` | `null` | no |
| `enable_zonal_shift` | Whether zonal shift is enabled | `bool` | `null` | no |
| `dns_record_client_routing_policy` | How traffic is distributed among the load balancer Availability Zones | `string` | `null` | no |
| `enforce_security_group_inbound_rules_on_private_link_traffic` | Whether inbound security group rules are enforced for traffic originating from a PrivateLink (NLB only) | `string` | `null` | no |
| `enable_prefix_for_ipv6_source_nat` | Whether to use an IPv6 prefix from each subnet for source NAT (NLB with UDP listeners only): on or off | `string` | `null` | no |
| `secondary_ips_auto_assigned_per_subnet` | Number of secondary IP addresses to auto-assign per subnet for source NAT (NLB only) | `number` | `null` | no |
| `ipam_pools` | IPAM pools to use with the load balancer | `object` | `null` | no |
| `minimum_load_balancer_capacity` | Minimum load balancer capacity configuration | `object` | `null` | no |
| `access_logs` | Access log configuration for the load balancer | `object` | `null` | no |
| `connection_logs` | Connection log configuration for the load balancer | `object` | `null` | no |
| `health_check_logs` | Health check log configuration for the load balancer (ALB only) | `object` | `null` | no |
| `timeouts` | Timeout configuration for the load balancer | `object` | `null` | no |
| `default_port` | Default port used for listeners and target groups when not specified | `number` | `80` | no |
| `default_protocol` | Default protocol used for listeners and target groups when not specified | `string` | `"HTTP"` | no |
| `listeners` | Map of listener configurations | `any` | `{}` | no |
| `target_groups` | Map of target group configurations | `any` | `{}` | no |
| `additional_target_group_attachments` | Map of additional target group attachments | `any` | `null` | no |
| `vpc_id` | VPC ID for the target groups and security group | `string` | `null` | no |
| `create_security_group` | Whether to create a managed security group for the ALB | `bool` | `true` | no |
| `create_network_lb_security_group` | Whether to also create the managed security group for network load balancers | `bool` | `false` | no |
| `security_group_name` | Name of the managed security group | `string` | `null` | no |
| `security_group_use_name_prefix` | Whether to use the security group name as a prefix (name_prefix) instead of an exact name | `bool` | `false` | no |
| `security_group_description` | Description of the managed security group | `string` | `null` | no |
| `security_group_tags` | Additional tags for the managed security group | `map(string)` | `{}` | no |
| `security_group_ingress_rules` | Map of ingress rules for the managed security group | `any` | `{}` | no |
| `security_group_egress_rules` | Map of egress rules for the managed security group | `any` | `{}` | no |
| `route53_records` | Map of Route53 alias records pointing to the load balancer | `any` | `{}` | no |
| `associate_web_acl` | Whether to associate a WAFv2 Web ACL with the load balancer | `bool` | `false` | no |
| `web_acl_arn` | ARN of the WAFv2 Web ACL to associate | `string` | `null` | no |
| `trust_stores` | Map of trust stores for mutual TLS authentication | `any` | `{}` | no |

Nested attributes of the `any`-typed maps (`listeners`, `target_groups`, `trust_stores`, security group rules, `route53_records`) are documented in the variable descriptions in [10-variables.tf](alb/10-variables.tf).

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

`listeners` and `listener_rules` contain the OIDC `client_secret` when `authenticate_oidc` is used, so Terraform treats them as sensitive: mark any root module output that re-exports them with `sensitive = true`.

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
