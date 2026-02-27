# =============================================================================
# Route53 DNS Records
# =============================================================================

resource "aws_route53_record" "this" {
  for_each = { for k, v in var.route53_records : k => v if local.create }

  zone_id = each.value.zone_id
  name    = lookup(each.value, "name", each.key)
  type    = lookup(each.value, "type", "A")

  alias {
    name                   = aws_lb.this[0].dns_name
    zone_id                = aws_lb.this[0].zone_id
    evaluate_target_health = lookup(each.value, "evaluate_target_health", true)
  }
}
