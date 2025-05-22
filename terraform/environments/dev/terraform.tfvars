aws_account_id      = "<YOUR-AWS-ACCOUNT-ID>"
region              = "us-east-1"
environment         = "dev"
project_name        = "huggingface"
name_prefix         = "huggingface-dev"
owner               = "DevOps-Team"
managed_by          = "Terraform"
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["us-east-1a", "us-east-1b"]
eks_cluster_name    = "huggingface-dev-cluster"
eks_cluster_version = "1.32"
admin_users         = ["admin@example.com"]
developer_users     = ["developer@example.com"]
alert_email         = "admin@example.com"
bucket_name         = "huggingface-terraform-state-dev"
enable_flow_logs    = false
flow_logs_retention = 30
log_retention_days  = 30
alb_listener_arn    = ""
allowed_origins     = ["*"]

# EKS Node Groups Configuration
eks_node_groups = {
  default = {
    instance_types = ["t3.large"]
    min_size       = 2
    max_size       = 5
    desired_size   = 3
    disk_size      = 20
  }
}
