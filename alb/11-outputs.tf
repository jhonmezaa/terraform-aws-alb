# =============================================================================
# Load Balancer Outputs
# =============================================================================

output "lb_id" {
  description = "The ID of the load balancer."
  value       = try(aws_lb.this[0].id, null)
}

output "lb_arn" {
  description = "The ARN of the load balancer."
  value       = try(aws_lb.this[0].arn, null)
}

output "lb_arn_suffix" {
  description = "The ARN suffix of the load balancer (for use with CloudWatch Metrics)."
  value       = try(aws_lb.this[0].arn_suffix, null)
}

output "lb_dns_name" {
  description = "The DNS name of the load balancer."
  value       = try(aws_lb.this[0].dns_name, null)
}

output "lb_zone_id" {
  description = "The canonical hosted zone ID of the load balancer (for Route53 alias records)."
  value       = try(aws_lb.this[0].zone_id, null)
}

output "lb_name" {
  description = "The name of the load balancer."
  value       = try(aws_lb.this[0].name, null)
}

# =============================================================================
# Listener Outputs
# =============================================================================

output "listeners" {
  description = "Map of all listeners created and their attributes."
  value       = aws_lb_listener.this
}

# =============================================================================
# Listener Rule Outputs
# =============================================================================

output "listener_rules" {
  description = "Map of all listener rules created and their attributes."
  value       = aws_lb_listener_rule.this
}

# =============================================================================
# Target Group Outputs
# =============================================================================

output "target_groups" {
  description = "Map of all target groups created and their attributes."
  value       = aws_lb_target_group.this
}

# =============================================================================
# Security Group Outputs
# =============================================================================

output "security_group_id" {
  description = "The ID of the managed security group."
  value       = try(aws_security_group.this[0].id, null)
}

output "security_group_arn" {
  description = "The ARN of the managed security group."
  value       = try(aws_security_group.this[0].arn, null)
}

# =============================================================================
# Route53 Outputs
# =============================================================================

output "route53_records" {
  description = "Map of Route53 records created."
  value       = aws_route53_record.this
}
