# Changelog

## [v1.0.2] - 2026-02-27

### Changed
- Standardize Terraform `required_version` to `~> 1.0` across module and examples


## [v1.0.1] - 2026-02-27

### Changed
- Update AWS provider constraint to `~> 6.0` across module and examples


All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-02-27

### Added

- Initial release of terraform-aws-alb module
- Application Load Balancer (ALB) support
- Network Load Balancer (NLB) support
- Gateway Load Balancer (GWLB) support
- Listeners with all action types (forward, redirect, fixed-response, weighted-forward)
- Authentication support (Cognito, OIDC)
- Listener rules with 6 condition types (host-header, path-pattern, http-header, http-request-method, query-string, source-ip)
- Target groups (instance, ip, lambda, alb target types)
- Target group attachments with Lambda permission support
- Additional SSL certificate management
- Managed security group with ingress/egress rules
- Route53 alias record integration
- WAFv2 Web ACL association
- Access logs, connection logs, and health check logs
- Cross-zone load balancing
- Deletion protection
- HTTP/2 support
- Mutual TLS authentication
- CORS and security response headers
- Standard naming convention: `{region_prefix}-alb-{account_name}-{project_name}`
- Region prefix auto-detection from AWS region
- 3 examples: basic-alb, complete-alb, nlb
