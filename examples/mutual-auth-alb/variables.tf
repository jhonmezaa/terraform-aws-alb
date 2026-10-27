variable "account_name" {
  description = "Account name for resource naming."
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming."
  type        = string
  default     = "mtls"
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
  description = "ARN of the ACM certificate for the HTTPS listener."
  type        = string
}

variable "trust_store_bucket" {
  description = "S3 bucket holding the CA bundle and the optional CRL."
  type        = string
}

variable "ca_bundle_s3_key" {
  description = "S3 key of the PEM CA certificates bundle."
  type        = string
  default     = "ca/ca-bundle.pem"
}

variable "crl_s3_key" {
  description = "S3 key of the PEM certificate revocation list. No revocation list is created when null."
  type        = string
  default     = null
}

variable "tags_common" {
  description = "Common tags."
  type        = map(string)
  default = {
    Environment = "dev"
  }
}
