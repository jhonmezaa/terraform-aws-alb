# =============================================================================
# Managed Security Group
# =============================================================================

resource "aws_security_group" "this" {
  count = local.create_security_group ? 1 : 0

  region = var.region

  name        = var.security_group_use_name_prefix ? null : local.sg_name
  name_prefix = var.security_group_use_name_prefix ? "${local.sg_name}-" : null
  description = var.security_group_description != null ? var.security_group_description : "Security group for ${local.lb_name}"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      Name      = local.sg_name
      ManagedBy = "Terraform"
    },
    local.tags,
    var.security_group_tags
  )
}

# =============================================================================
# Ingress Rules
# =============================================================================

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = {
    for k, v in var.security_group_ingress_rules : k => v
    if local.create_security_group
  }

  region = var.region

  security_group_id = aws_security_group.this[0].id

  description = lookup(each.value, "description", null)
  cidr_ipv4   = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6   = lookup(each.value, "cidr_ipv6", null)
  # from_port/to_port default to each other when only one is set (single-port rules)
  from_port                    = lookup(each.value, "ip_protocol", "tcp") == "-1" ? null : try(coalesce(lookup(each.value, "from_port", null), lookup(each.value, "to_port", null)), null)
  to_port                      = lookup(each.value, "ip_protocol", "tcp") == "-1" ? null : try(coalesce(lookup(each.value, "to_port", null), lookup(each.value, "from_port", null)), null)
  ip_protocol                  = lookup(each.value, "ip_protocol", "tcp")
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)

  tags = merge(
    {
      Name      = coalesce(lookup(each.value, "name", null), "${local.sg_name}-ingress-${each.key}")
      ManagedBy = "Terraform"
    },
    local.tags,
    lookup(each.value, "tags", {})
  )
}

# =============================================================================
# Egress Rules
# =============================================================================

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = {
    for k, v in var.security_group_egress_rules : k => v
    if local.create_security_group
  }

  region = var.region

  security_group_id = aws_security_group.this[0].id

  description = lookup(each.value, "description", null)
  cidr_ipv4   = lookup(each.value, "cidr_ipv4", null)
  cidr_ipv6   = lookup(each.value, "cidr_ipv6", null)
  # from_port/to_port default to each other when only one is set (single-port rules)
  from_port                    = lookup(each.value, "ip_protocol", "tcp") == "-1" ? null : try(coalesce(lookup(each.value, "from_port", null), lookup(each.value, "to_port", null)), null)
  to_port                      = lookup(each.value, "ip_protocol", "tcp") == "-1" ? null : try(coalesce(lookup(each.value, "to_port", null), lookup(each.value, "from_port", null)), null)
  ip_protocol                  = lookup(each.value, "ip_protocol", "tcp")
  prefix_list_id               = lookup(each.value, "prefix_list_id", null)
  referenced_security_group_id = lookup(each.value, "referenced_security_group_id", null)

  tags = merge(
    {
      Name      = coalesce(lookup(each.value, "name", null), "${local.sg_name}-egress-${each.key}")
      ManagedBy = "Terraform"
    },
    local.tags,
    lookup(each.value, "tags", {})
  )
}
