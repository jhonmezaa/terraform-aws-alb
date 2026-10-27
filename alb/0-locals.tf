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

  # Effective region: explicit var.region (provider v6 per-resource region) or provider region
  region = coalesce(var.region, data.aws_region.current.region)

  region_prefix = var.region_prefix != null ? var.region_prefix : lookup(
    local.region_prefix_map,
    local.region,
    local.region
  )

  # Name prefix: includes region prefix with trailing dash, or empty string
  name_prefix = var.use_region_prefix ? "${local.region_prefix}-" : ""

  # =============================================================================
  # Creation Flags
  # =============================================================================

  create = var.create

  # Managed SG: always for ALB; opt-in for NLB (SGs can only be added to an NLB at creation time)
  create_security_group = local.create && var.create_security_group && (
    var.load_balancer_type == "application" || (var.load_balancer_type == "network" && var.create_network_lb_security_group)
  )

  # Security groups attached to the LB (user-provided + managed). For NLB, null when empty
  # so that existing NLBs created without security groups are not replaced.
  lb_security_groups_list = compact(concat(var.security_groups, local.create_security_group ? [aws_security_group.this[0].id] : []))
  lb_security_groups      = var.load_balancer_type == "network" && length(local.lb_security_groups_list) == 0 ? null : local.lb_security_groups_list

  # =============================================================================
  # Tags
  # =============================================================================

  # var.tags is kept for backward compatibility; it overrides var.tags_common on key conflicts
  tags = merge(var.tags_common, var.tags)

  # =============================================================================
  # Load Balancer Naming
  # =============================================================================

  lb_type_prefix = var.load_balancer_type == "application" ? "alb" : (
    var.load_balancer_type == "network" ? "nlb" : "gwlb"
  )

  # Truncated to 32 chars (AWS limit); a trailing hyphen left by the truncation is removed
  lb_name = coalesce(
    var.name,
    trimsuffix(substr("${local.name_prefix}${local.lb_type_prefix}-${var.account_name}-${var.project_name}", 0, 32), "-")
  )

  # Security group naming. AWS rejects SG names starting with "sg-", so without
  # region prefix the type goes first: {alb|nlb}-sg-{account_name}-{project_name}
  sg_name = coalesce(
    var.security_group_name,
    var.use_region_prefix
    ? "${local.name_prefix}sg-${local.lb_type_prefix}-${var.account_name}-${var.project_name}"
    : "${local.lb_type_prefix}-sg-${var.account_name}-${var.project_name}"
  )

  # =============================================================================
  # Target Group Naming
  # =============================================================================

  target_group_names = {
    for k, v in var.target_groups : k => coalesce(
      lookup(v, "name", null),
      trimsuffix(substr("${local.name_prefix}tg-${var.account_name}-${var.project_name}-${k}", 0, 32), "-")
    )
  }

  # =============================================================================
  # Trust Store Naming
  # =============================================================================

  trust_store_names = {
    for k, v in var.trust_stores : k => coalesce(
      lookup(v, "name", null),
      trimsuffix(substr("${local.name_prefix}ts-${var.account_name}-${var.project_name}-${k}", 0, 32), "-")
    )
  }

  # Flatten trust store revocation lists
  trust_store_revocations = merge([
    for ts_key, ts in var.trust_stores : {
      for rev_key, rev in lookup(ts, "revocation_lists", {}) :
      "${ts_key}/${rev_key}" => merge(rev, {
        trust_store_key = ts_key
      })
    }
  ]...)

  # =============================================================================
  # Listener Protocols
  # =============================================================================

  listener_protocols = { for k, v in var.listeners : k => lookup(v, "protocol", var.default_protocol) }

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
