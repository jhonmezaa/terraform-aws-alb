# =============================================================================
# Complete ALB Example
# =============================================================================
# Creates a production-ready ALB with:
# - HTTPS listener with SSL certificate
# - HTTP to HTTPS redirect
# - Weighted target groups
# - Listener rules with path-based routing
# - Fixed response for health checks
# - Route53 DNS record
# - WAF association placeholder
# - Access logging
# - Managed security group
# - CORS headers
# =============================================================================

module "alb" {
  source = "../../alb"

  account_name = var.account_name
  project_name = var.project_name

  # Load balancer
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.public_subnets
  vpc_id                     = var.vpc_id
  enable_deletion_protection = true
  enable_http2               = true
  idle_timeout               = 60
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"

  # Security group
  create_security_group = true
  security_group_ingress_rules = {
    http = {
      description = "Allow HTTP from anywhere"
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      description = "Allow HTTPS from anywhere"
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      description = "Allow all outbound"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  # Target groups
  target_groups = {
    web-primary = {
      port             = 80
      protocol         = "HTTP"
      target_type      = "instance"
      protocol_version = "HTTP1"

      health_check = {
        enabled             = true
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
        path                = "/health"
        protocol            = "HTTP"
        matcher             = "200"
        timeout             = 5
      }

      stickiness = {
        type            = "lb_cookie"
        cookie_duration = 86400
        enabled         = true
      }

      deregistration_delay = 300
    }

    web-canary = {
      port             = 80
      protocol         = "HTTP"
      target_type      = "instance"
      protocol_version = "HTTP1"

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        interval            = 15
        path                = "/health"
        protocol            = "HTTP"
        matcher             = "200"
        timeout             = 5
      }
    }

    api = {
      port             = 8080
      protocol         = "HTTP"
      target_type      = "ip"
      protocol_version = "HTTP2"

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        unhealthy_threshold = 3
        interval            = 15
        path                = "/api/health"
        protocol            = "HTTP"
        matcher             = "200"
      }

      load_balancing_algorithm_type = "least_outstanding_requests"
    }
  }

  # Listeners
  listeners = {
    # HTTP -> HTTPS redirect
    http = {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    # HTTPS listener with weighted forwarding
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-3-2021-06"

      # CORS headers
      routing_http_response_access_control_allow_origin_header_value  = "*"
      routing_http_response_access_control_allow_methods_header_value = "GET, POST, PUT, DELETE, OPTIONS"
      routing_http_response_access_control_allow_headers_header_value = "Content-Type, Authorization"
      routing_http_response_access_control_max_age_header_value       = "86400"

      # Security headers
      routing_http_response_strict_transport_security_header_value = "max-age=31536000; includeSubDomains"
      routing_http_response_x_content_type_options_header_value    = "nosniff"
      routing_http_response_x_frame_options_header_value           = "DENY"

      # Default: weighted forward (90/10 canary)
      weighted_forward = {
        target_groups = [
          {
            target_group_key = "web-primary"
            weight           = 90
          },
          {
            target_group_key = "web-canary"
            weight           = 10
          }
        ]

        stickiness = {
          duration = 3600
          enabled  = true
        }
      }

      # Listener rules
      rules = {
        # API routing
        api = {
          priority = 100

          actions = [
            {
              type             = "forward"
              target_group_key = "api"
            }
          ]

          conditions = [
            {
              path_pattern = {
                values = ["/api/*"]
              }
            }
          ]
        }

        # Health check endpoint
        health = {
          priority = 200

          actions = [
            {
              type         = "fixed_response"
              content_type = "text/plain"
              message_body = "OK"
              status_code  = "200"
            }
          ]

          conditions = [
            {
              path_pattern = {
                values = ["/alb-health"]
              }
            }
          ]
        }
      }
    }
  }

  # Route53 records
  route53_records = var.route53_zone_id != null ? {
    a_record = {
      zone_id = var.route53_zone_id
      name    = var.domain_name
      type    = "A"
    }
    aaaa_record = {
      zone_id = var.route53_zone_id
      name    = var.domain_name
      type    = "AAAA"
    }
  } : {}

  tags = var.tags
}
