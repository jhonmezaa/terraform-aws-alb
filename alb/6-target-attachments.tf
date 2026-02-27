# =============================================================================
# Target Group Attachments (Primary)
# =============================================================================

resource "aws_lb_target_group_attachment" "this" {
  for_each = {
    for k, v in var.target_groups : k => v
    if local.create && lookup(v, "target_id", null) != null && lookup(v, "create_attachment", true)
  }

  target_group_arn  = aws_lb_target_group.this[each.key].arn
  target_id         = each.value.target_id
  port              = lookup(each.value, "target_type", "instance") == "lambda" ? null : lookup(each.value, "port", null)
  availability_zone = lookup(each.value, "availability_zone", null)
}

# =============================================================================
# Target Group Attachments (Additional)
# =============================================================================

resource "aws_lb_target_group_attachment" "additional" {
  for_each = { for k, v in local.additional_tg_attachments : k => v if local.create }

  target_group_arn  = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id         = each.value.target_id
  port              = lookup(each.value, "port", null)
  availability_zone = lookup(each.value, "availability_zone", null)
}

# =============================================================================
# Lambda Permissions
# =============================================================================

resource "aws_lambda_permission" "this" {
  for_each = { for k, v in local.lambda_target_groups : k => v if local.create }

  function_name = each.value.target_id
  qualifier     = lookup(each.value, "lambda_qualifier", null)

  statement_id       = lookup(each.value, "lambda_statement_id", "AllowExecutionFromALB-${each.key}")
  action             = lookup(each.value, "lambda_action", "lambda:InvokeFunction")
  principal          = lookup(each.value, "lambda_principal", "elasticloadbalancing.${data.aws_partition.current.dns_suffix}")
  source_account     = lookup(each.value, "lambda_source_account", null)
  event_source_token = lookup(each.value, "lambda_event_source_token", null)
  source_arn         = aws_lb_target_group.this[each.key].arn
}
