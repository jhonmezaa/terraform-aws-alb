# =============================================================================
# WAFv2 Web ACL Association
# =============================================================================

resource "aws_wafv2_web_acl_association" "this" {
  count = local.create && var.associate_web_acl ? 1 : 0

  resource_arn = aws_lb.this[0].arn
  web_acl_arn  = var.web_acl_arn
}
