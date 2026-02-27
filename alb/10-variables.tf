# =============================================================================
# General Variables
# =============================================================================

variable "create" {
  description = "Controls if resources should be created."
  type        = bool
  default     = true
}

variable "account_name" {
  description = "Account name for resource naming."
  type        = string

  validation {
    condition     = length(var.account_name) > 0 && length(var.account_name) <= 32
    error_message = "account_name debe tener entre 1 y 32 caracteres."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.account_name))
    error_message = "account_name solo puede contener letras minúsculas, números y guiones."
  }
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string

  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 32
    error_message = "project_name debe tener entre 1 y 32 caracteres."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name solo puede contener letras minúsculas, números y guiones."
  }
}

variable "region_prefix" {
  description = "Region prefix for naming. If not provided, will be derived from current region."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# =============================================================================
# Load Balancer Configuration
# =============================================================================

variable "name" {
  description = "Name of the load balancer. If not provided, follows naming convention: {region_prefix}-{alb|nlb|gwlb}-{account_name}-{project_name}"
  type        = string
  default     = null
}

variable "load_balancer_type" {
  description = "Type of load balancer to create: application, network, or gateway."
  type        = string
  default     = "application"

  validation {
    condition     = contains(["application", "network", "gateway"], var.load_balancer_type)
    error_message = "load_balancer_type must be one of: application, network, gateway."
  }
}

variable "internal" {
  description = "If true, the load balancer will be internal (not internet-facing)."
  type        = bool
  default     = false
}

variable "subnets" {
  description = "List of subnet IDs to attach to the load balancer."
  type        = list(string)
  default     = null
}

variable "subnet_mapping" {
  description = "List of subnet mapping configurations with optional Elastic IP allocations."
  type = list(object({
    subnet_id            = string
    allocation_id        = optional(string)
    ipv6_address         = optional(string)
    private_ipv4_address = optional(string)
  }))
  default = null
}

variable "security_groups" {
  description = "List of security group IDs to attach to the ALB (in addition to the managed security group)."
  type        = list(string)
  default     = []
}

variable "ip_address_type" {
  description = "Type of IP addresses used by the subnets: ipv4 or dualstack."
  type        = string
  default     = null
}

variable "customer_owned_ipv4_pool" {
  description = "ID of the customer owned IPv4 address pool."
  type        = string
  default     = null
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing."
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer."
  type        = bool
  default     = true
}

variable "drop_invalid_header_fields" {
  description = "Whether HTTP headers with header fields that are not valid are removed by the load balancer (ALB only)."
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Whether HTTP/2 is enabled on the ALB."
  type        = bool
  default     = null
}

variable "idle_timeout" {
  description = "Time in seconds that the connection is allowed to be idle (ALB only)."
  type        = number
  default     = null
}

variable "client_keep_alive" {
  description = "Client keep alive value in seconds. Minimum 60, maximum 604800 (ALB only)."
  type        = number
  default     = null
}

variable "preserve_host_header" {
  description = "Whether the ALB should preserve the Host header in the HTTP request (ALB only)."
  type        = bool
  default     = null
}

variable "xff_header_processing_mode" {
  description = "How the ALB processes the X-Forwarded-For header: append, preserve, or remove (ALB only)."
  type        = string
  default     = null
}

variable "enable_xff_client_port" {
  description = "Whether the X-Forwarded-For header should preserve the source port (ALB only)."
  type        = bool
  default     = null
}

variable "enable_tls_version_and_cipher_suite_headers" {
  description = "Whether the ALB adds TLS version and cipher suite headers (ALB only)."
  type        = bool
  default     = null
}

variable "desync_mitigation_mode" {
  description = "How the ALB handles requests that might pose a security risk: monitor, defensive, or strictest (ALB only)."
  type        = string
  default     = null
}

variable "enable_waf_fail_open" {
  description = "Whether to route requests to targets if the WAF is unavailable (ALB only)."
  type        = bool
  default     = null
}

variable "enable_zonal_shift" {
  description = "Whether zonal shift is enabled."
  type        = bool
  default     = null
}

variable "dns_record_client_routing_policy" {
  description = "How traffic is distributed among the load balancer Availability Zones."
  type        = string
  default     = null
}

variable "enforce_security_group_inbound_rules_on_private_link_traffic" {
  description = "Whether inbound security group rules are enforced for traffic originating from a PrivateLink (NLB only)."
  type        = string
  default     = null
}

variable "minimum_load_balancer_capacity" {
  description = "Minimum load balancer capacity configuration."
  type = object({
    capacity_units = number
  })
  default = null
}

# =============================================================================
# Logging
# =============================================================================

variable "access_logs" {
  description = "Access log configuration for the load balancer."
  type = object({
    bucket  = string
    enabled = optional(bool, true)
    prefix  = optional(string)
  })
  default = null
}

variable "connection_logs" {
  description = "Connection log configuration for the load balancer."
  type = object({
    bucket  = string
    enabled = optional(bool, true)
    prefix  = optional(string)
  })
  default = null
}

# =============================================================================
# Timeouts
# =============================================================================

variable "timeouts" {
  description = "Timeout configuration for the load balancer."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

# =============================================================================
# Default Port and Protocol
# =============================================================================

variable "default_port" {
  description = "Default port used for listeners and target groups when not specified."
  type        = number
  default     = 80
}

variable "default_protocol" {
  description = "Default protocol used for listeners and target groups when not specified."
  type        = string
  default     = "HTTP"
}

# =============================================================================
# Listeners
# =============================================================================

variable "listeners" {
  description = <<-EOT
    Map of listener configurations. Each key is a unique identifier for the listener.

    Each listener supports the following attributes:
    - port: Listener port (defaults to var.default_port)
    - protocol: Listener protocol (defaults to var.default_protocol)
    - ssl_policy: SSL policy for HTTPS/TLS listeners
    - certificate_arn: ARN of the default SSL certificate
    - additional_certificate_arns: List of additional SSL certificate ARNs
    - alpn_policy: ALPN policy for TLS listeners
    - tcp_idle_timeout_seconds: TCP idle timeout (TCP protocol only)
    - mutual_authentication: Mutual TLS configuration { mode, trust_store_arn, ... }
    - tags: Additional tags for this listener

    Default action (choose one):
    - forward: { target_group_key or target_group_arn }
    - weighted_forward: { target_groups = [{ target_group_key/arn, weight }], stickiness = { duration, enabled } }
    - redirect: { host, path, port, protocol, query, status_code }
    - fixed_response: { content_type, message_body, status_code }
    - authenticate_cognito: { user_pool_arn, user_pool_client_id, user_pool_domain, ... }
    - authenticate_oidc: { authorization_endpoint, client_id, client_secret, issuer, token_endpoint, user_info_endpoint, ... }

    Nested rules:
    - rules: Map of listener rules, each with actions and conditions

    CORS and Security Headers (ALB only):
    - routing_http_response_access_control_allow_*
    - routing_http_response_content_security_policy_header_value
    - routing_http_response_strict_transport_security_header_value
    - routing_http_response_x_content_type_options_header_value
    - routing_http_response_x_frame_options_header_value

    mTLS Headers (HTTPS only):
    - routing_http_request_x_amzn_mtls_clientcert_*
    - routing_http_request_x_amzn_tls_*
  EOT
  type        = any
  default     = {}
}

# =============================================================================
# Target Groups
# =============================================================================

variable "target_groups" {
  description = <<-EOT
    Map of target group configurations. Each key is a unique identifier.

    Each target group supports:
    - name/name_prefix: Target group name (auto-generated if not specified)
    - port: Target port (defaults to var.default_port, null for Lambda)
    - protocol: Target protocol (defaults to var.default_protocol, null for Lambda)
    - protocol_version: HTTP/1.1, HTTP/2, or gRPC
    - target_type: instance, ip, lambda, or alb
    - vpc_id: VPC ID (defaults to var.vpc_id)
    - ip_address_type: IP address type

    Health check:
    - health_check: { enabled, healthy_threshold, unhealthy_threshold, interval, matcher, path, port, protocol, timeout }

    Stickiness:
    - stickiness: { type (lb_cookie|app_cookie|source_ip|source_ip_dest_ip|source_ip_dest_ip_proto), cookie_duration, cookie_name, enabled }

    Load balancing:
    - load_balancing_algorithm_type: round_robin, least_outstanding_requests, weighted_random
    - load_balancing_anomaly_mitigation: on/off
    - load_balancing_cross_zone_enabled: use_load_balancer_configuration, true, false

    Connection:
    - connection_termination: Close connections on deregistration
    - deregistration_delay: Delay in seconds before deregistering targets
    - slow_start: Slow start duration in seconds

    Target failover (NLB):
    - target_failover: [{ on_deregistration, on_unhealthy }]

    Target group health:
    - target_group_health: { dns_failover: { minimum_healthy_targets_count/percentage }, unhealthy_state_routing: { ... } }

    Target health state:
    - target_health_state: { enable_unhealthy_connection_termination, unhealthy_draining_interval }

    Target attachment:
    - target_id: Target ID (instance ID, IP, Lambda ARN, or ALB ARN)
    - create_attachment: Whether to create the attachment (default: true)
    - availability_zone: AZ for cross-zone targets

    Lambda integration:
    - attach_lambda_permission: Create Lambda invoke permission (default: true for Lambda targets)
    - lambda_qualifier: Lambda alias/version qualifier
    - lambda_multi_value_headers_enabled: Enable multi-value headers for Lambda targets

    Proxy:
    - proxy_protocol_v2: Enable proxy protocol v2
    - preserve_client_ip: Preserve client IP
  EOT
  type        = any
  default     = {}
}

# =============================================================================
# Additional Target Group Attachments
# =============================================================================

variable "additional_target_group_attachments" {
  description = <<-EOT
    Map of additional target group attachments. Use when attaching multiple targets to a target group.

    Each attachment requires:
    - target_group_key: Key referencing a target group created by this module
    - target_id: Target ID (instance ID, IP address, Lambda ARN)
    - port: Port for the target (optional)
    - availability_zone: AZ for cross-zone targets (optional)
  EOT
  type        = any
  default     = null
}

# =============================================================================
# VPC
# =============================================================================

variable "vpc_id" {
  description = "VPC ID for the target groups and security group."
  type        = string
  default     = null
}

# =============================================================================
# Security Group
# =============================================================================

variable "create_security_group" {
  description = "Whether to create a managed security group for the ALB."
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name of the managed security group. If not provided, follows naming convention."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description of the managed security group."
  type        = string
  default     = null
}

variable "security_group_tags" {
  description = "Additional tags for the managed security group."
  type        = map(string)
  default     = {}
}

variable "security_group_ingress_rules" {
  description = <<-EOT
    Map of ingress rules for the managed security group.

    Each rule supports:
    - description: Rule description
    - cidr_ipv4: IPv4 CIDR block
    - cidr_ipv6: IPv6 CIDR block
    - from_port: Start port
    - to_port: End port
    - ip_protocol: Protocol (default: tcp)
    - prefix_list_id: Prefix list ID
    - referenced_security_group_id: Source security group ID
    - tags: Additional tags
  EOT
  type        = any
  default     = {}
}

variable "security_group_egress_rules" {
  description = <<-EOT
    Map of egress rules for the managed security group.

    Each rule supports same attributes as ingress rules.
  EOT
  type        = any
  default     = {}
}

# =============================================================================
# Route53
# =============================================================================

variable "route53_records" {
  description = <<-EOT
    Map of Route53 alias records pointing to the load balancer.

    Each record supports:
    - zone_id: Route53 hosted zone ID
    - name: Record name (defaults to the map key)
    - type: Record type: A, AAAA, or CNAME (default: A)
    - evaluate_target_health: Whether to evaluate target health (default: true)
  EOT
  type        = any
  default     = {}
}

# =============================================================================
# WAF
# =============================================================================

variable "associate_web_acl" {
  description = "Whether to associate a WAFv2 Web ACL with the load balancer."
  type        = bool
  default     = false
}

variable "web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL to associate."
  type        = string
  default     = null
}
