# =============================================================================
# Load Balancer (ALB / NLB / GWLB)
# =============================================================================

resource "aws_lb" "this" {
  count = local.create ? 1 : 0

  name               = local.lb_name
  load_balancer_type = var.load_balancer_type
  internal           = var.internal

  # Network
  subnets                          = var.subnets
  security_groups                  = var.load_balancer_type == "application" ? compact(concat(var.security_groups, local.create_security_group ? [aws_security_group.this[0].id] : [])) : null
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
    var.tags
  )
}
