provider "aws" {
  region = var.region
}

terraform {
  required_version = "~> 1.11.4"

  backend "s3" {
    bucket       = "huggingface-terraform-state-dev"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = var.managed_by
    Owner       = var.owner
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix         = var.name_prefix
  region              = var.region
  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  enable_flow_logs    = var.enable_flow_logs
  flow_logs_role_arn  = module.iam.flow_logs_role_arn
  flow_logs_retention = var.flow_logs_retention
  availability_zones  = var.availability_zones

  tags = local.common_tags
}

module "vpc_endpoints" {
  source = "../../modules/vpc_endpoints"

  name_prefix                     = var.name_prefix
  project_name                    = var.project_name
  environment                     = var.environment
  region                          = var.region
  vpc_id                          = module.vpc.vpc_id
  private_subnet_ids              = module.vpc.private_subnet_ids
  vpc_endpoints_security_group_id = module.security_groups.vpc_endpoints_security_group_id

  tags = local.common_tags
}

module "security_groups" {
  source = "../../modules/security_groups"

  name_prefix  = var.name_prefix
  region       = var.region
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
  tags         = local.common_tags

  depends_on = [
    module.vpc
  ]
}

module "iam" {
  source = "../../modules/iam"

  name_prefix             = var.name_prefix
  project_name            = var.project_name
  environment             = var.environment
  aws_account_id          = var.aws_account_id
  region                  = var.region
  admin_users             = var.admin_users
  developer_users         = var.developer_users
  enable_flow_logs        = var.enable_flow_logs
  cluster_oidc_issuer_url = var.cluster_oidc_issuer_url
  cluster_oidc_thumbprint = var.cluster_oidc_thumbprint
  tags                    = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  name_prefix  = var.name_prefix
  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  vpc_id     = module.vpc.vpc_id
  vpc_cidr   = module.vpc.vpc_cidr
  subnet_ids = module.vpc.private_subnet_ids

  cluster_version = var.eks_cluster_version

  eks_cluster_role_arn = module.iam.eks_cluster_role_arn
  eks_node_role_arn    = module.iam.eks_node_role_arn

  eks_cluster_security_group_id     = module.security_groups.eks_cluster_security_group_id
  eks_worker_node_security_group_id = module.security_groups.eks_worker_node_security_group_id

  node_desired_size   = var.eks_node_groups["default"].desired_size
  node_max_size       = var.eks_node_groups["default"].max_size
  node_min_size       = var.eks_node_groups["default"].min_size
  node_instance_types = var.eks_node_groups["default"].instance_types
  log_retention_days  = var.log_retention_days

  tags = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  name_prefix    = var.name_prefix
  project_name   = var.project_name
  environment    = var.environment
  aws_account_id = var.aws_account_id
  region         = var.region
  tags           = local.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix             = var.name_prefix
  region                  = var.region
  project_name            = var.project_name
  environment             = var.environment
  aws_account_id          = var.aws_account_id
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  alert_email             = var.alert_email
  tags                    = local.common_tags

  depends_on = [
    module.eks
  ]
}

module "waf" {
  source = "../../modules/waf"

  name_prefix = var.name_prefix
  rate_limit  = var.waf_rate_limit
  tags        = local.common_tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  name_prefix             = var.name_prefix
  api_gateway_domain_name = trimsuffix(trimprefix(module.api_gateway.api_endpoint, "https://"), "/${var.environment}")
  waf_web_acl_arn         = module.waf.web_acl_arn
  tags                    = local.common_tags

  depends_on = [
    module.api_gateway,
    module.waf
  ]
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  name_prefix                   = var.name_prefix
  project_name                  = var.project_name
  region                        = var.region
  environment                   = var.environment
  vpc_id                        = module.vpc.vpc_id
  vpc_cidr                      = var.vpc_cidr
  private_subnet_ids            = module.vpc.private_subnet_ids
  allowed_origins               = var.allowed_origins
  log_retention_days            = var.log_retention_days
  alerts_topic_arn              = module.monitoring.alerts_topic_arn
  aws_account_id                = var.aws_account_id
  api_gateway_security_group_id = module.security_groups.api_gateway_security_group_id
  alb_security_group_id         = module.security_groups.alb_security_group_id
  alb_listener_arn              = var.alb_listener_arn # Will be configured later by Kubernetes deployment
  tags                          = local.common_tags

  depends_on = [
    module.vpc,
    module.monitoring,
    module.security_groups
  ]
}
