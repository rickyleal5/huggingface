variable "name_prefix" {
  description = "Prefix to be used for resource names"
  type        = string
}

variable "rate_limit" {
  description = "Rate limit for the WAF rule"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
} 