variable "primary_region" {
  description = "The primary AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "secondary_region" {
  description = "The secondary AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "dr-pipeline"
}

variable "vpc_cidr_primary" {
  description = "CIDR block for primary VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "vpc_cidr_secondary" {
  description = "CIDR block for secondary VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "db_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

variable "dns_domain" {
  description = "The domain name for the DR setup"
  type        = string
  default     = "dr-pipeline-test-9912.com"
}
