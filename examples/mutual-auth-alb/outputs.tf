output "lb_dns_name" {
  description = "DNS name of the load balancer."
  value       = module.alb.lb_dns_name
}

output "lb_arn" {
  description = "ARN of the load balancer."
  value       = module.alb.lb_arn
}

output "trust_store_arns" {
  description = "Trust store ARNs by key."
  value       = module.alb.trust_store_arns
}

output "trust_store_revocations" {
  description = "Trust store revocation lists created."
  value       = module.alb.trust_store_revocations
}

output "listeners" {
  description = "Map of listeners created."
  value       = module.alb.listeners
}
