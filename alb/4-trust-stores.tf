# =============================================================================
# Trust Stores (mTLS)
# =============================================================================

resource "aws_lb_trust_store" "this" {
  for_each = { for k, v in var.trust_stores : k => v if local.create }

  region = var.region

  # name and name_prefix are mutually exclusive
  name        = lookup(each.value, "name_prefix", null) != null ? null : local.trust_store_names[each.key]
  name_prefix = lookup(each.value, "name_prefix", null)

  ca_certificates_bundle_s3_bucket         = each.value.ca_certificates_bundle_s3_bucket
  ca_certificates_bundle_s3_key            = each.value.ca_certificates_bundle_s3_key
  ca_certificates_bundle_s3_object_version = lookup(each.value, "ca_certificates_bundle_s3_object_version", null)

  tags = merge(
    {
      Name      = local.trust_store_names[each.key]
      ManagedBy = "Terraform"
    },
    local.tags,
    lookup(each.value, "tags", {})
  )
}

# =============================================================================
# Trust Store Revocations (CRLs)
# =============================================================================

resource "aws_lb_trust_store_revocation" "this" {
  for_each = { for k, v in local.trust_store_revocations : k => v if local.create }

  region = var.region

  trust_store_arn               = aws_lb_trust_store.this[each.value.trust_store_key].arn
  revocations_s3_bucket         = each.value.revocations_s3_bucket
  revocations_s3_key            = each.value.revocations_s3_key
  revocations_s3_object_version = lookup(each.value, "revocations_s3_object_version", null)
}
