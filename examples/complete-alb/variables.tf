variable "account_name" {
  description = "Account name for resource naming."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string
  default     = "platform"
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS."
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID."
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Domain name for the Route53 record."
  type        = string
  default     = null
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool."
  type        = string
}

variable "cognito_user_pool_client_id" {
  description = "Client ID of the Cognito User Pool App Client."
  type        = string
}

variable "cognito_user_pool_domain" {
  description = "Domain of the Cognito User Pool."
  type        = string
}

variable "oidc_issuer" {
  description = "OIDC issuer URL."
  type        = string
}

variable "oidc_client_id" {
  description = "OIDC client ID."
  type        = string
}

variable "oidc_client_secret" {
  description = "OIDC client secret."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default = {
    Environment = "prod"
  }
}
