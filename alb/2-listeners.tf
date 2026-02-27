# =============================================================================
# Listeners
# =============================================================================

resource "aws_lb_listener" "this" {
  for_each = { for k, v in var.listeners : k => v if local.create }

  load_balancer_arn = aws_lb.this[0].arn

  port            = lookup(each.value, "port", var.default_port)
  protocol        = lookup(each.value, "protocol", var.default_protocol)
  ssl_policy      = contains(["HTTPS", "TLS"], lookup(each.value, "protocol", var.default_protocol)) ? lookup(each.value, "ssl_policy", "ELBSecurityPolicy-TLS13-1-3-2021-06") : null
  certificate_arn = lookup(each.value, "certificate_arn", null)
  alpn_policy     = lookup(each.value, "alpn_policy", null)

  tcp_idle_timeout_seconds = lookup(each.value, "protocol", var.default_protocol) == "TCP" ? lookup(each.value, "tcp_idle_timeout_seconds", null) : null

  # ---------------------------------------------------------------------------
  # Mutual TLS Authentication
  # ---------------------------------------------------------------------------
  dynamic "mutual_authentication" {
    for_each = lookup(each.value, "mutual_authentication", null) != null ? [each.value.mutual_authentication] : []

    content {
      mode                             = mutual_authentication.value.mode
      trust_store_arn                  = lookup(mutual_authentication.value, "trust_store_arn", null)
      advertise_trust_store_ca_names   = lookup(mutual_authentication.value, "advertise_trust_store_ca_names", null)
      ignore_client_certificate_expiry = lookup(mutual_authentication.value, "ignore_client_certificate_expiry", null)
    }
  }

  # ---------------------------------------------------------------------------
  # Default Action: Forward
  # ---------------------------------------------------------------------------
  dynamic "default_action" {
    for_each = lookup(each.value, "forward", null) != null ? [each.value.forward] : []

    content {
      type             = "forward"
      target_group_arn = lookup(default_action.value, "target_group_key", null) != null ? aws_lb_target_group.this[default_action.value.target_group_key].arn : lookup(default_action.value, "target_group_arn", null)
      order            = lookup(each.value, "order", null)
    }
  }

  # ---------------------------------------------------------------------------
  # Default Action: Weighted Forward
  # ---------------------------------------------------------------------------
  dynamic "default_action" {
    for_each = lookup(each.value, "weighted_forward", null) != null ? [each.value.weighted_forward] : []

    content {
      type  = "forward"
      order = lookup(each.value, "order", null)

      forward {
        dynamic "target_group" {
          for_each = default_action.value.target_groups

          content {
            arn    = lookup(target_group.value, "target_group_key", null) != null ? aws_lb_target_group.this[target_group.value.target_group_key].arn : target_group.value.arn
            weight = lookup(target_group.value, "weight", 1)
          }
        }

        dynamic "stickiness" {
          for_each = lookup(default_action.value, "stickiness", null) != null ? [default_action.value.stickiness] : []

          content {
            duration = lookup(stickiness.value, "duration", 3600)
            enabled  = lookup(stickiness.value, "enabled", false)
          }
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Default Action: Redirect
  # ---------------------------------------------------------------------------
  dynamic "default_action" {
    for_each = lookup(each.value, "redirect", null) != null ? [each.value.redirect] : []

    content {
      type  = "redirect"
      order = lookup(each.value, "order", null)

      redirect {
        host        = lookup(default_action.value, "host", "#{host}")
        path        = lookup(default_action.value, "path", "/#{path}")
        port        = lookup(default_action.value, "port", "#{port}")
        protocol    = lookup(default_action.value, "protocol", "#{protocol}")
        query       = lookup(default_action.value, "query", "#{query}")
        status_code = lookup(default_action.value, "status_code", "HTTP_301")
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Default Action: Fixed Response
  # ---------------------------------------------------------------------------
  dynamic "default_action" {
    for_each = lookup(each.value, "fixed_response", null) != null ? [each.value.fixed_response] : []

    content {
      type  = "fixed-response"
      order = lookup(each.value, "order", null)

      fixed_response {
        content_type = default_action.value.content_type
        message_body = lookup(default_action.value, "message_body", null)
        status_code  = lookup(default_action.value, "status_code", "200")
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Default Action: Authenticate Cognito
  # ---------------------------------------------------------------------------
  dynamic "default_action" {
    for_each = lookup(each.value, "authenticate_cognito", null) != null ? [each.value.authenticate_cognito] : []

    content {
      type  = "authenticate-cognito"
      order = lookup(each.value, "order", null)

      authenticate_cognito {
        user_pool_arn              = default_action.value.user_pool_arn
        user_pool_client_id        = default_action.value.user_pool_client_id
        user_pool_domain           = default_action.value.user_pool_domain
        scope                      = lookup(default_action.value, "scope", null)
        session_cookie_name        = lookup(default_action.value, "session_cookie_name", null)
        session_timeout            = lookup(default_action.value, "session_timeout", null)
        on_unauthenticated_request = lookup(default_action.value, "on_unauthenticated_request", null)

        dynamic "authentication_request_extra_params" {
          for_each = lookup(default_action.value, "authentication_request_extra_params", null) != null ? [default_action.value.authentication_request_extra_params] : []

          content {
          }
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Default Action: Authenticate OIDC
  # ---------------------------------------------------------------------------
  dynamic "default_action" {
    for_each = lookup(each.value, "authenticate_oidc", null) != null ? [each.value.authenticate_oidc] : []

    content {
      type  = "authenticate-oidc"
      order = lookup(each.value, "order", null)

      authenticate_oidc {
        authorization_endpoint     = default_action.value.authorization_endpoint
        client_id                  = default_action.value.client_id
        client_secret              = default_action.value.client_secret
        issuer                     = default_action.value.issuer
        token_endpoint             = default_action.value.token_endpoint
        user_info_endpoint         = default_action.value.user_info_endpoint
        scope                      = lookup(default_action.value, "scope", null)
        session_cookie_name        = lookup(default_action.value, "session_cookie_name", null)
        session_timeout            = lookup(default_action.value, "session_timeout", null)
        on_unauthenticated_request = lookup(default_action.value, "on_unauthenticated_request", null)

        dynamic "authentication_request_extra_params" {
          for_each = lookup(default_action.value, "authentication_request_extra_params", null) != null ? [default_action.value.authentication_request_extra_params] : []

          content {
          }
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # mTLS Request Routing Headers (HTTPS only)
  # ---------------------------------------------------------------------------
  routing_http_request_x_amzn_mtls_clientcert_header_name               = lookup(each.value, "routing_http_request_x_amzn_mtls_clientcert_header_name", null)
  routing_http_request_x_amzn_mtls_clientcert_issuer_header_name        = lookup(each.value, "routing_http_request_x_amzn_mtls_clientcert_issuer_header_name", null)
  routing_http_request_x_amzn_mtls_clientcert_leaf_header_name          = lookup(each.value, "routing_http_request_x_amzn_mtls_clientcert_leaf_header_name", null)
  routing_http_request_x_amzn_mtls_clientcert_serial_number_header_name = lookup(each.value, "routing_http_request_x_amzn_mtls_clientcert_serial_number_header_name", null)
  routing_http_request_x_amzn_mtls_clientcert_subject_header_name       = lookup(each.value, "routing_http_request_x_amzn_mtls_clientcert_subject_header_name", null)
  routing_http_request_x_amzn_mtls_clientcert_validity_header_name      = lookup(each.value, "routing_http_request_x_amzn_mtls_clientcert_validity_header_name", null)
  routing_http_request_x_amzn_tls_cipher_suite_header_name              = lookup(each.value, "routing_http_request_x_amzn_tls_cipher_suite_header_name", null)
  routing_http_request_x_amzn_tls_version_header_name                   = lookup(each.value, "routing_http_request_x_amzn_tls_version_header_name", null)

  # ---------------------------------------------------------------------------
  # CORS & Security Response Headers (HTTP/HTTPS only)
  # ---------------------------------------------------------------------------
  routing_http_response_access_control_allow_credentials_header_value = lookup(each.value, "routing_http_response_access_control_allow_credentials_header_value", null)
  routing_http_response_access_control_allow_headers_header_value     = lookup(each.value, "routing_http_response_access_control_allow_headers_header_value", null)
  routing_http_response_access_control_allow_methods_header_value     = lookup(each.value, "routing_http_response_access_control_allow_methods_header_value", null)
  routing_http_response_access_control_allow_origin_header_value      = lookup(each.value, "routing_http_response_access_control_allow_origin_header_value", null)
  routing_http_response_access_control_expose_headers_header_value    = lookup(each.value, "routing_http_response_access_control_expose_headers_header_value", null)
  routing_http_response_access_control_max_age_header_value           = lookup(each.value, "routing_http_response_access_control_max_age_header_value", null)
  routing_http_response_content_security_policy_header_value          = lookup(each.value, "routing_http_response_content_security_policy_header_value", null)
  routing_http_response_server_enabled                                = lookup(each.value, "routing_http_response_server_enabled", null)
  routing_http_response_strict_transport_security_header_value        = lookup(each.value, "routing_http_response_strict_transport_security_header_value", null)
  routing_http_response_x_content_type_options_header_value           = lookup(each.value, "routing_http_response_x_content_type_options_header_value", null)
  routing_http_response_x_frame_options_header_value                  = lookup(each.value, "routing_http_response_x_frame_options_header_value", null)

  tags = merge(
    {
      Name      = "${local.lb_name}-${each.key}"
      ManagedBy = "Terraform"
    },
    var.tags,
    lookup(each.value, "tags", {})
  )

  depends_on = [aws_lb_target_group.this]
}
