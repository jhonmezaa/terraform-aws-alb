# =============================================================================
# Load Balancer (ALB / NLB / GWLB)
# =============================================================================

resource "aws_lb" "this" {
  count = local.create ? 1 : 0

  region = var.region

  name               = var.lb_name_prefix != null ? null : local.lb_name
  name_prefix        = var.lb_name_prefix
  load_balancer_type = var.load_balancer_type
  internal           = var.internal

  # Network
  subnets                          = var.subnets
  security_groups                  = contains(["application", "network"], var.load_balancer_type) ? local.lb_security_groups : null
  ip_address_type                  = var.ip_address_type
  customer_owned_ipv4_pool         = var.customer_owned_ipv4_pool
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  # Protection
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.load_balancer_type == "application" ? var.drop_invalid_header_fields : null

  # HTTP/2
  enable_http2 = var.load_balancer_type == "application" ? var.enable_http2 : null

  # Timeouts
  idle_timeout      = var.load_balancer_type == "application" ? var.idle_timeout : null
  client_keep_alive = var.load_balancer_type == "application" ? var.client_keep_alive : null

  # Headers
  preserve_host_header                        = var.load_balancer_type == "application" ? var.preserve_host_header : null
  xff_header_processing_mode                  = var.load_balancer_type == "application" ? var.xff_header_processing_mode : null
  enable_xff_client_port                      = var.load_balancer_type == "application" ? var.enable_xff_client_port : null
  enable_tls_version_and_cipher_suite_headers = var.load_balancer_type == "application" ? var.enable_tls_version_and_cipher_suite_headers : null

  # Desync mitigation
  desync_mitigation_mode = var.load_balancer_type == "application" ? var.desync_mitigation_mode : null

  # WAF
  enable_waf_fail_open = var.load_balancer_type == "application" ? var.enable_waf_fail_open : null

  # Zonal shift
  enable_zonal_shift = var.enable_zonal_shift

  # DNS routing
  dns_record_client_routing_policy = var.dns_record_client_routing_policy

  # PrivateLink (NLB)
  enforce_security_group_inbound_rules_on_private_link_traffic = var.load_balancer_type == "network" ? var.enforce_security_group_inbound_rules_on_private_link_traffic : null

  # IPv6 source NAT & secondary IPs (NLB)
  enable_prefix_for_ipv6_source_nat      = var.load_balancer_type == "network" ? var.enable_prefix_for_ipv6_source_nat : null
  secondary_ips_auto_assigned_per_subnet = var.load_balancer_type == "network" ? var.secondary_ips_auto_assigned_per_subnet : null

  # Subnet mapping
  dynamic "subnet_mapping" {
    for_each = var.subnet_mapping != null ? var.subnet_mapping : []

    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = lookup(subnet_mapping.value, "allocation_id", null)
      ipv6_address         = lookup(subnet_mapping.value, "ipv6_address", null)
      private_ipv4_address = lookup(subnet_mapping.value, "private_ipv4_address", null)
    }
  }

  # Access logs
  dynamic "access_logs" {
    for_each = var.access_logs != null ? [var.access_logs] : []

    content {
      bucket  = access_logs.value.bucket
      enabled = lookup(access_logs.value, "enabled", true)
      prefix  = lookup(access_logs.value, "prefix", null)
    }
  }

  # Connection logs
  dynamic "connection_logs" {
    for_each = var.connection_logs != null ? [var.connection_logs] : []

    content {
      bucket  = connection_logs.value.bucket
      enabled = lookup(connection_logs.value, "enabled", true)
      prefix  = lookup(connection_logs.value, "prefix", null)
    }
  }

  # Health check logs (ALB)
  dynamic "health_check_logs" {
    for_each = var.health_check_logs != null && var.load_balancer_type == "application" ? [var.health_check_logs] : []

    content {
      bucket  = health_check_logs.value.bucket
      enabled = lookup(health_check_logs.value, "enabled", true)
      prefix  = lookup(health_check_logs.value, "prefix", null)
    }
  }

  # IPAM pools
  dynamic "ipam_pools" {
    for_each = var.ipam_pools != null ? [var.ipam_pools] : []

    content {
      ipv4_ipam_pool_id = ipam_pools.value.ipv4_ipam_pool_id
    }
  }

  # Minimum capacity
  dynamic "minimum_load_balancer_capacity" {
    for_each = var.minimum_load_balancer_capacity != null ? [var.minimum_load_balancer_capacity] : []

    content {
      capacity_units = minimum_load_balancer_capacity.value.capacity_units
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts != null ? [var.timeouts] : []

    content {
      create = lookup(timeouts.value, "create", null)
      update = lookup(timeouts.value, "update", null)
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  tags = merge(
    {
      Name      = local.lb_name
      ManagedBy = "Terraform"
    },
    local.tags
  )

  lifecycle {
    ignore_changes = [
      tags["elasticbeanstalk:shared-elb-environment-count"]
    ]
  }
}
