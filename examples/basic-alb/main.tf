# =============================================================================
# Basic ALB Example
# =============================================================================
# Creates a simple internet-facing ALB with:
# - HTTP listener forwarding to a target group
# - Managed security group allowing HTTP from anywhere
# - Single target group with health checks
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
  enable_deletion_protection = false

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
    web = {
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"

      health_check = {
        enabled             = true
        healthy_threshold   = 3
        unhealthy_threshold = 3
        interval            = 30
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
      }
    }
  }

  # Listeners
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "web"
      }
    }
  }

  tags = var.tags
}
