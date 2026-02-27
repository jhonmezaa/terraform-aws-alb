# =============================================================================
# Listener Rules
# =============================================================================

resource "aws_lb_listener_rule" "this" {
  for_each = { for k, v in local.listener_rules : k => v if local.create }

  listener_arn = lookup(each.value, "listener_arn", null) != null ? each.value.listener_arn : aws_lb_listener.this[each.value.listener_key].arn
  priority     = lookup(each.value, "priority", null)

  # ---------------------------------------------------------------------------
  # Actions
  # ---------------------------------------------------------------------------

  # Forward action
  dynamic "action" {
    for_each = [for action in lookup(each.value, "actions", []) : action if lookup(action, "type", "") == "forward"]

    content {
      type             = "forward"
      target_group_arn = lookup(action.value, "target_group_key", null) != null ? aws_lb_target_group.this[action.value.target_group_key].arn : lookup(action.value, "target_group_arn", null)
      order            = lookup(action.value, "order", null)
    }
  }

  # Weighted forward action
  dynamic "action" {
    for_each = [for action in lookup(each.value, "actions", []) : action if lookup(action, "type", "") == "weighted_forward"]

    content {
      type  = "forward"
      order = lookup(action.value, "order", null)

      forward {
        dynamic "target_group" {
          for_each = action.value.target_groups

          content {
            arn    = lookup(target_group.value, "target_group_key", null) != null ? aws_lb_target_group.this[target_group.value.target_group_key].arn : target_group.value.arn
            weight = lookup(target_group.value, "weight", 1)
          }
        }

        dynamic "stickiness" {
          for_each = lookup(action.value, "stickiness", null) != null ? [action.value.stickiness] : []

          content {
            duration = lookup(stickiness.value, "duration", 3600)
            enabled  = lookup(stickiness.value, "enabled", false)
          }
        }
      }
    }
  }

  # Redirect action
  dynamic "action" {
    for_each = [for action in lookup(each.value, "actions", []) : action if lookup(action, "type", "") == "redirect"]

    content {
      type  = "redirect"
      order = lookup(action.value, "order", null)

      redirect {
        host        = lookup(action.value, "host", "#{host}")
        path        = lookup(action.value, "path", "/#{path}")
        port        = lookup(action.value, "port", "#{port}")
        protocol    = lookup(action.value, "protocol", "#{protocol}")
        query       = lookup(action.value, "query", "#{query}")
        status_code = lookup(action.value, "status_code", "HTTP_301")
      }
    }
  }

  # Fixed response action
  dynamic "action" {
    for_each = [for action in lookup(each.value, "actions", []) : action if lookup(action, "type", "") == "fixed_response"]

    content {
      type  = "fixed-response"
      order = lookup(action.value, "order", null)

      fixed_response {
        content_type = action.value.content_type
        message_body = lookup(action.value, "message_body", null)
        status_code  = lookup(action.value, "status_code", "200")
      }
    }
  }

  # Authenticate Cognito action
  dynamic "action" {
    for_each = [for action in lookup(each.value, "actions", []) : action if lookup(action, "type", "") == "authenticate_cognito"]

    content {
      type  = "authenticate-cognito"
      order = lookup(action.value, "order", null)

      authenticate_cognito {
        user_pool_arn              = action.value.user_pool_arn
        user_pool_client_id        = action.value.user_pool_client_id
        user_pool_domain           = action.value.user_pool_domain
        scope                      = lookup(action.value, "scope", null)
        session_cookie_name        = lookup(action.value, "session_cookie_name", null)
        session_timeout            = lookup(action.value, "session_timeout", null)
        on_unauthenticated_request = lookup(action.value, "on_unauthenticated_request", null)
      }
    }
  }

  # Authenticate OIDC action
  dynamic "action" {
    for_each = [for action in lookup(each.value, "actions", []) : action if lookup(action, "type", "") == "authenticate_oidc"]

    content {
      type  = "authenticate-oidc"
      order = lookup(action.value, "order", null)

      authenticate_oidc {
        authorization_endpoint     = action.value.authorization_endpoint
        client_id                  = action.value.client_id
        client_secret              = action.value.client_secret
        issuer                     = action.value.issuer
        token_endpoint             = action.value.token_endpoint
        user_info_endpoint         = action.value.user_info_endpoint
        scope                      = lookup(action.value, "scope", null)
        session_cookie_name        = lookup(action.value, "session_cookie_name", null)
        session_timeout            = lookup(action.value, "session_timeout", null)
        on_unauthenticated_request = lookup(action.value, "on_unauthenticated_request", null)
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Conditions
  # ---------------------------------------------------------------------------

  dynamic "condition" {
    for_each = lookup(each.value, "conditions", [])

    content {
      # Host header condition
      dynamic "host_header" {
        for_each = lookup(condition.value, "host_header", null) != null ? [condition.value.host_header] : []

        content {
          values = host_header.value.values
        }
      }

      # Path pattern condition
      dynamic "path_pattern" {
        for_each = lookup(condition.value, "path_pattern", null) != null ? [condition.value.path_pattern] : []

        content {
          values = path_pattern.value.values
        }
      }

      # HTTP header condition
      dynamic "http_header" {
        for_each = lookup(condition.value, "http_header", null) != null ? [condition.value.http_header] : []

        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }

      # HTTP request method condition
      dynamic "http_request_method" {
        for_each = lookup(condition.value, "http_request_method", null) != null ? [condition.value.http_request_method] : []

        content {
          values = http_request_method.value.values
        }
      }

      # Query string condition
      dynamic "query_string" {
        for_each = lookup(condition.value, "query_string", null) != null ? condition.value.query_string : []

        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value.value
        }
      }

      # Source IP condition
      dynamic "source_ip" {
        for_each = lookup(condition.value, "source_ip", null) != null ? [condition.value.source_ip] : []

        content {
          values = source_ip.value.values
        }
      }
    }
  }

  tags = merge(
    {
      Name      = "${local.lb_name}-rule-${each.value.rule_key}"
      ManagedBy = "Terraform"
    },
    var.tags,
    lookup(each.value, "tags", {})
  )
}
