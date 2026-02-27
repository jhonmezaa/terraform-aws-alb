# =============================================================================
# NLB Example
# =============================================================================
# Creates a Network Load Balancer with:
# - TCP listener on port 80
# - TLS listener on port 443 (optional)
# - TCP target group with health checks
# - Cross-zone load balancing
# =============================================================================

module "nlb" {
  source = "../../alb"

  account_name = var.account_name
  project_name = var.project_name

  # Load balancer
  load_balancer_type               = "network"
  internal                         = false
  subnets                          = var.public_subnets
  vpc_id                           = var.vpc_id
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true

  # No managed security group for NLB
  create_security_group = false

  # Target groups
  target_groups = {
    tcp = {
      port        = 80
      protocol    = "TCP"
      target_type = "instance"

      health_check = {
        enabled             = true
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
        protocol            = "TCP"
      }

      target_failover = [
        {
          on_deregistration = "rebalance"
          on_unhealthy      = "rebalance"
        }
      ]

      target_health_state = {
        enable_unhealthy_connection_termination = true
      }
    }

    tls = {
      port        = 443
      protocol    = "TLS"
      target_type = "instance"

      health_check = {
        enabled             = true
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
        protocol            = "TCP"
      }
    }
  }

  # Listeners
  listeners = {
    tcp = {
      port     = 80
      protocol = "TCP"

      forward = {
        target_group_key = "tcp"
      }
    }

    tls = {
      port            = 443
      protocol        = "TLS"
      certificate_arn = var.certificate_arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-3-2021-06"

      forward = {
        target_group_key = "tls"
      }
    }
  }

  tags = var.tags
}
