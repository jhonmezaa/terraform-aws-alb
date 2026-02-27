output "lb_dns_name" {
  description = "DNS name of the load balancer."
  value       = module.alb.lb_dns_name
}

output "lb_arn" {
  description = "ARN of the load balancer."
  value       = module.alb.lb_arn
}

output "lb_arn_suffix" {
  description = "ARN suffix for CloudWatch metrics."
  value       = module.alb.lb_arn_suffix
}

output "listeners" {
  description = "Map of listeners created."
  value       = module.alb.listeners
}

output "listener_rules" {
  description = "Map of listener rules created."
  value       = module.alb.listener_rules
}

output "target_groups" {
  description = "Map of target groups created."
  value       = module.alb.target_groups
}

output "security_group_id" {
  description = "Security group ID."
  value       = module.alb.security_group_id
}

output "route53_records" {
  description = "Route53 records created."
  value       = module.alb.route53_records
}
