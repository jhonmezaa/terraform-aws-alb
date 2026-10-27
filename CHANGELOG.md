# Changelog

All notable changes to this project will be documented in this file.

## [v1.1.2] - 2026-10-27

### Changed

- Docs: normalize CHANGELOG format: move the preamble below the title, use `## [vX.Y.Z] - YYYY-MM-DD` headings for all entries, and add the missing `v1.0.6` and `v1.0.7` entries reconstructed from git history

## [v1.1.1] - 2026-10-27

### Changed

- Use minimum-only version constraints in the module (`alb/`): AWS provider `~> 6.28` -> `>= 6.28`, so callers are not blocked from newer major provider versions
- Set module `required_version` to `>= 1.3` (was `~> 1.0`): the minimum real Terraform version, since variables use `optional()` object attributes with defaults (Terraform 1.3+)
- Examples (root modules) keep pessimistic constraints: `required_version` `~> 1.3`, AWS provider `~> 6.28`
- Update requirements tables in the root README and example READMEs

## [v1.1.0] - 2026-10-27

### Added

- Trust stores and revocation lists (`trust_stores` variable, `aws_lb_trust_store` / `aws_lb_trust_store_revocation`); listeners can reference them with `mutual_authentication.trust_store_key`
- `jwt-validation` action for listener default actions (`jwt_validation`) and listener rules (`type = "jwt_validation"`), including `additional_claim`
- Listener rule `transform` (host header rewrite and URL rewrite)
- `regex_values` for `host_header`, `path_pattern` and `http_header` rule conditions
- Load balancer: `health_check_logs`, `ipam_pools`, `lb_name_prefix`, `enable_prefix_for_ipv6_source_nat`, `secondary_ips_auto_assigned_per_subnet`
- `region` variable applied to all resources (AWS provider v6 per-resource region); the region prefix is derived from it when set
- Security groups on NLB: `security_groups` is now passed to network load balancers, and the managed security group can be enabled with `create_network_lb_security_group` (default `false`)
- `security_group_use_name_prefix` (default `false`) and per-rule `name` for security group rule `Name` tags
- Target groups: `target_control_port`; attachments: `quic_server_id`
- `tags_common` variable merged into all resource tags
- Outputs: `lb_tags_all`, `security_group_name`, `target_group_attachments`, `trust_stores`, `trust_store_arns`, `trust_store_revocations`
- `mutual-auth-alb` example; `complete-alb` example now shows JWT validation, rewrite transforms, regex conditions and logs

### Changed

- Load balancer, security group and target group names are built from `name_prefix`, so `use_region_prefix = false` is now honored. With the default (`use_region_prefix = true`) generated names are unchanged
- Truncated names (32 chars) no longer end with a hyphen
- Without region prefix the managed security group is named `{alb|nlb}-sg-{account_name}-{project_name}` (AWS rejects names starting with `sg-`)
- `routing_http_response_*` attributes are only set on HTTP/HTTPS listeners and `routing_http_request_*` only on HTTPS listeners
- GENEVE (GWLB) listeners omit `port` and `protocol`
- Security group rules default `to_port` to `from_port` (and vice versa) when only one is set
- Target group attachments now depend on Lambda permissions; additional attachments ignore `port` for Lambda target groups
- Lifecycle on the load balancer ignores the `elasticbeanstalk:shared-elb-environment-count` tag
- `tags` is kept for backward compatibility and merged on top of `tags_common`

### Fixed

- Target groups with `name_prefix` no longer also set `name` (conflicting arguments)

### Upgrade notes

- If you used `use_region_prefix = false`, generated names now drop the region prefix: the load balancer, target groups and security group will be **replaced**. Pin the previous names with `name`, `security_group_name` and `target_groups.<key>.name` to avoid it
- AWS provider constraint raised from `~> 6.0` to `~> 6.28` (>= 6.28, < 7.0), required by the features listed above. Run `terraform init -upgrade` if your lock file pins an older 6.x

## [v1.0.8] - 2026-04-25

### Changed

- Update README documentation and CHANGELOG formatting

## [v1.0.7] - 2026-02-28

### Changed

- Documentation only: reformat README and CHANGELOG (no module code changes)

## [v1.0.6] - 2026-02-28

### Fixed

- Truncate auto-generated load balancer and target group names to 32 characters (AWS limit) with `substr(..., 0, 32)` in `alb/0-locals.tf` and `alb/5-target-groups.tf`, avoiding deployment failures with long `account_name`, `project_name` or target group keys

## [v1.0.5] - 2026-02-28

### Fixed

- Security group ingress/egress rules now auto-null `from_port` and `to_port` when `ip_protocol = "-1"` (all protocols), preventing AWS API errors

## [v1.0.4] - 2026-02-27

### Changed

- Update complete-alb example with Cognito and OIDC authentication listener rules demonstrating `authentication_request_extra_params`

## [v1.0.3] - 2026-02-27

### Fixed

- Fix `authentication_request_extra_params` in listeners: replace empty dynamic blocks with direct `map(string)` attribute for Cognito and OIDC actions
- Add missing `authentication_request_extra_params` attribute to Cognito and OIDC actions in listener rules
- Update README.md version requirements to match actual module constraints

## [v1.0.2] - 2026-02-27

### Changed

- Standardize Terraform `required_version` to `~> 1.0` across module and examples

## [v1.0.1] - 2026-02-27

### Changed

- Update AWS provider constraint to `~> 6.0` across module and examples

## [v1.0.0] - 2026-02-27

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
