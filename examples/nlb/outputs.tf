output "lb_dns_name" {
  description = "DNS name of the NLB."
  value       = module.nlb.lb_dns_name
}

output "lb_arn" {
  description = "ARN of the NLB."
  value       = module.nlb.lb_arn
}

output "target_groups" {
  description = "Target groups created."
  value       = module.nlb.target_groups
}
