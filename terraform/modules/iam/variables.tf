variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "name_prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "admin_users" {
  description = "List of IAM users to be added to admin group"
  type        = list(string)
  default     = []
}

variable "developer_users" {
  description = "List of IAM users to be added to developer group"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the EKS cluster"
  type        = string
}

variable "cluster_oidc_thumbprint" {
  description = "The thumbprint of the OIDC issuer certificate"
  type        = string
  default     = ""
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs"
  type        = bool
  default     = false
} 