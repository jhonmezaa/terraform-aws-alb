locals {
  # =============================================================================
  # Region Prefix Mapping
  # =============================================================================

  region_prefix_map = {
    # US Regions
    "us-east-1" = "ause1"
    "us-east-2" = "ause2"
    "us-west-1" = "ausw1"
    "us-west-2" = "ausw2"
    # EU Regions
    "eu-west-1"    = "euwe1"
    "eu-west-2"    = "euwe2"
    "eu-west-3"    = "euwe3"
    "eu-central-1" = "euce1"
    "eu-central-2" = "euce2"
    "eu-north-1"   = "euno1"
    "eu-south-1"   = "euso1"
    "eu-south-2"   = "euso2"
    # AP Regions
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "ap-southeast-3" = "apse3"
    "ap-southeast-4" = "apse4"
    "ap-northeast-1" = "apne1"
    "ap-northeast-2" = "apne2"
    "ap-northeast-3" = "apne3"
    "ap-south-1"     = "apso1"
    "ap-south-2"     = "apso2"
    "ap-east-1"      = "apea1"
    # SA Regions
    "sa-east-1" = "saea1"
    # CA Regions
    "ca-central-1" = "cace1"
    "ca-west-1"    = "cawe1"
    # ME Regions
    "me-south-1"   = "meso1"
    "me-central-1" = "mece1"
    # AF Regions
    "af-south-1" = "afso1"
    # IL Regions
    "il-central-1" = "ilce1"
  }

  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    data.aws_region.current.id,
    data.aws_region.current.id
  )

  # Name prefix: includes region prefix with trailing dash, or empty string
  name_prefix = var.use_region_prefix ? "${local.region_prefix}-" : ""

  # =============================================================================
  # Creation Flags
  # =============================================================================

  create                = var.create
  create_security_group = local.create && var.create_security_group && var.load_balancer_type == "application"

  # =============================================================================
  # Load Balancer Naming
  # =============================================================================

  lb_type_prefix = var.load_balancer_type == "application" ? "alb" : (
    var.load_balancer_type == "network" ? "nlb" : "gwlb"
  )

  lb_name = var.name != null ? var.name : substr("${local.region_prefix}-${local.lb_type_prefix}-${var.account_name}-${var.project_name}", 0, 32)

  # Security group naming
  sg_name = var.security_group_name != null ? var.security_group_name : "${local.region_prefix}-sg-${local.lb_type_prefix}-${var.account_name}-${var.project_name}"

  # =============================================================================
  # Flatten Listener Rules
  # =============================================================================

  # Flatten listener rules from nested map to flat map for for_each
  listener_rules = merge([
    for listener_key, listener in var.listeners : {
      for rule_key, rule in lookup(listener, "rules", {}) :
      "${listener_key}/${rule_key}" => merge(rule, {
        listener_key = listener_key
        rule_key     = rule_key
      })
    }
  ]...)

  # =============================================================================
  # Flatten Additional Certificates
  # =============================================================================

  additional_certs = merge([
    for listener_key, listener in var.listeners : {
      for idx, cert_arn in lookup(listener, "additional_certificate_arns", []) :
      "${listener_key}/${idx}" => {
        listener_key    = listener_key
        certificate_arn = cert_arn
      }
    }
  ]...)

  # =============================================================================
  # Lambda Target Groups (need Lambda permission)
  # =============================================================================

  lambda_target_groups = {
    for k, v in var.target_groups : k => v
    if lookup(v, "target_type", "instance") == "lambda" && lookup(v, "attach_lambda_permission", true)
  }

  # =============================================================================
  # Additional Target Group Attachments
  # =============================================================================

  additional_tg_attachments = var.additional_target_group_attachments != null ? var.additional_target_group_attachments : {}
}
