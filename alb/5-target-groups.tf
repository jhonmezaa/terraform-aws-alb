# =============================================================================
# Target Groups
# =============================================================================

resource "aws_lb_target_group" "this" {
  for_each = { for k, v in var.target_groups : k => v if local.create }

  name        = lookup(each.value, "name", null) != null ? each.value.name : "${local.region_prefix}-tg-${var.account_name}-${var.project_name}-${each.key}"
  name_prefix = lookup(each.value, "name_prefix", null)

  port             = lookup(each.value, "target_type", "instance") == "lambda" ? null : lookup(each.value, "port", var.default_port)
  protocol         = lookup(each.value, "target_type", "instance") == "lambda" ? null : lookup(each.value, "protocol", var.default_protocol)
  protocol_version = lookup(each.value, "protocol_version", null)
  target_type      = lookup(each.value, "target_type", "instance")
  vpc_id           = lookup(each.value, "target_type", "instance") == "lambda" ? null : lookup(each.value, "vpc_id", var.vpc_id)
  ip_address_type  = lookup(each.value, "ip_address_type", null)

  # Connection & Deregistration
  connection_termination = lookup(each.value, "connection_termination", null)
  deregistration_delay   = lookup(each.value, "deregistration_delay", null)
  slow_start             = lookup(each.value, "slow_start", null)

  # Load Balancing
  load_balancing_algorithm_type     = lookup(each.value, "load_balancing_algorithm_type", null)
  load_balancing_anomaly_mitigation = lookup(each.value, "load_balancing_anomaly_mitigation", null)
  load_balancing_cross_zone_enabled = lookup(each.value, "load_balancing_cross_zone_enabled", null)

  # Proxy
  proxy_protocol_v2  = lookup(each.value, "proxy_protocol_v2", null)
  preserve_client_ip = lookup(each.value, "preserve_client_ip", null)

  # Lambda
  lambda_multi_value_headers_enabled = lookup(each.value, "target_type", "instance") == "lambda" ? lookup(each.value, "lambda_multi_value_headers_enabled", null) : null

  # ---------------------------------------------------------------------------
  # Health Check
  # ---------------------------------------------------------------------------
  dynamic "health_check" {
    for_each = lookup(each.value, "health_check", null) != null ? [each.value.health_check] : []

    content {
      enabled             = lookup(health_check.value, "enabled", true)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      interval            = lookup(health_check.value, "interval", null)
      matcher             = lookup(health_check.value, "matcher", null)
      path                = lookup(health_check.value, "path", null)
      port                = lookup(health_check.value, "port", null)
      protocol            = lookup(health_check.value, "protocol", null)
      timeout             = lookup(health_check.value, "timeout", null)
    }
  }

  # ---------------------------------------------------------------------------
  # Stickiness
  # ---------------------------------------------------------------------------
  dynamic "stickiness" {
    for_each = lookup(each.value, "stickiness", null) != null ? [each.value.stickiness] : []

    content {
      type            = stickiness.value.type
      cookie_duration = lookup(stickiness.value, "cookie_duration", null)
      cookie_name     = lookup(stickiness.value, "cookie_name", null)
      enabled         = lookup(stickiness.value, "enabled", true)
    }
  }

  # ---------------------------------------------------------------------------
  # Target Failover (NLB)
  # ---------------------------------------------------------------------------
  dynamic "target_failover" {
    for_each = lookup(each.value, "target_failover", null) != null ? each.value.target_failover : []

    content {
      on_deregistration = target_failover.value.on_deregistration
      on_unhealthy      = target_failover.value.on_unhealthy
    }
  }

  # ---------------------------------------------------------------------------
  # Target Group Health
  # ---------------------------------------------------------------------------
  dynamic "target_group_health" {
    for_each = lookup(each.value, "target_group_health", null) != null ? [each.value.target_group_health] : []

    content {
      dynamic "dns_failover" {
        for_each = lookup(target_group_health.value, "dns_failover", null) != null ? [target_group_health.value.dns_failover] : []

        content {
          minimum_healthy_targets_count      = lookup(dns_failover.value, "minimum_healthy_targets_count", null)
          minimum_healthy_targets_percentage = lookup(dns_failover.value, "minimum_healthy_targets_percentage", null)
        }
      }

      dynamic "unhealthy_state_routing" {
        for_each = lookup(target_group_health.value, "unhealthy_state_routing", null) != null ? [target_group_health.value.unhealthy_state_routing] : []

        content {
          minimum_healthy_targets_count      = lookup(unhealthy_state_routing.value, "minimum_healthy_targets_count", null)
          minimum_healthy_targets_percentage = lookup(unhealthy_state_routing.value, "minimum_healthy_targets_percentage", null)
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Target Health State
  # ---------------------------------------------------------------------------
  dynamic "target_health_state" {
    for_each = lookup(each.value, "target_health_state", null) != null ? [each.value.target_health_state] : []

    content {
      enable_unhealthy_connection_termination = target_health_state.value.enable_unhealthy_connection_termination
      unhealthy_draining_interval             = lookup(target_health_state.value, "unhealthy_draining_interval", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name      = lookup(each.value, "name", "${local.region_prefix}-tg-${var.account_name}-${var.project_name}-${each.key}")
      ManagedBy = "Terraform"
    },
    var.tags,
    lookup(each.value, "tags", {})
  )
}
