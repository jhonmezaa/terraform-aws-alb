# =============================================================================
# Mutual TLS (mTLS) ALB Example
# =============================================================================
# Creates an internet-facing ALB that authenticates clients with X.509
# certificates:
# - Trust store built from a CA bundle stored in S3
# - Optional certificate revocation list (CRL)
# - HTTPS listener in mTLS "verify" mode, advertising the trusted CA names
# - Client certificate details forwarded to targets as HTTP headers
# - HTTP listener redirecting to HTTPS
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
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      description = "Allow HTTPS from anywhere"
      from_port   = 443
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

  # Trust stores
  trust_stores = {
    clients = {
      ca_certificates_bundle_s3_bucket = var.trust_store_bucket
      ca_certificates_bundle_s3_key    = var.ca_bundle_s3_key

      revocation_lists = var.crl_s3_key != null ? {
        crl = {
          revocations_s3_bucket = var.trust_store_bucket
          revocations_s3_key    = var.crl_s3_key
        }
      } : {}
    }
  }

  # Target groups
  target_groups = {
    app = {
      port        = 80
      protocol    = "HTTP"
      target_type = "instance"

      health_check = {
        path     = "/health"
        protocol = "HTTP"
        matcher  = "200"
      }
    }
  }

  # Listeners
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.certificate_arn
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"

      mutual_authentication = {
        mode                           = "verify"
        trust_store_key                = "clients"
        advertise_trust_store_ca_names = "on"
      }

      # Rename the client certificate headers forwarded to the targets
      routing_http_request_x_amzn_mtls_clientcert_subject_header_name  = "X-Client-Cert-Subject"
      routing_http_request_x_amzn_mtls_clientcert_issuer_header_name   = "X-Client-Cert-Issuer"
      routing_http_request_x_amzn_mtls_clientcert_validity_header_name = "X-Client-Cert-Validity"

      forward = {
        target_group_key = "app"
      }
    }
  }

  tags_common = var.tags_common
}
