variable "name_prefix" {
  description = "Prefix to be used for resource names"
  type        = string
}

variable "api_gateway_domain_name" {
  description = "Domain name of the API Gateway endpoint"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with CloudFront"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 