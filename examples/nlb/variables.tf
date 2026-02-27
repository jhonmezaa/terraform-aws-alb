variable "account_name" {
  description = "Account name for resource naming."
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string
  default     = "services"
}

variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for TLS."
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags."
  type        = map(string)
  default = {
    Environment = "prod"
  }
}
