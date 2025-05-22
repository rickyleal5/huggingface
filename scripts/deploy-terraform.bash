#!/bin/bash
set -e  # Exit on error

# Set environment variables
export AWS_PROFILE=<AWS_SSO_PROFILE>
export ENVIRONMENT="dev"
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="<YOUR-AWS-ACCOUNT-ID>"
export PROJECT_NAME="huggingface"
export CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"

# Login to AWS SSO
aws sso login --profile ${AWS_PROFILE}

# Navigate to the environment directory
cd "$(dirname "$0")/../terraform/environments/${ENVIRONMENT}"

echo "Phase 1: Deploying core infrastructure (VPC, Security Groups, EKS, basic IAM)..."
# Run terraform commands for core infrastructure only
terraform fmt
terraform init
terraform validate

# Plan and apply only the core infrastructure
terraform plan -out=tfplan \
  -var="alb_listener_arn=" \
  -var="enable_flow_logs=false" \
  -var="cluster_oidc_issuer_url=" \
  -var="cluster_oidc_thumbprint=" \
  -target=module.iam.aws_iam_role.flow_logs \
  -target=module.iam.aws_iam_role_policy.flow_logs \
  -target=module.iam.aws_iam_role.aws_load_balancer_controller \
  -target=module.iam.aws_iam_role_policy_attachment.aws_load_balancer_controller \
  -target=module.iam.aws_iam_role.eks_cluster \
  -target=module.iam.aws_iam_role.eks_node \
  -target=module.iam.aws_iam_role_policy_attachment.eks_cluster \
  -target=module.iam.aws_iam_role_policy_attachment.eks_service \
  -target=module.iam.aws_iam_role_policy_attachment.eks_node \
  -target=module.iam.aws_iam_role_policy_attachment.eks_cni \
  -target=module.iam.aws_iam_role_policy_attachment.eks_ecr \
  -target=module.vpc.aws_vpc.main \
  -target=module.vpc.aws_subnet.private \
  -target=module.vpc.aws_subnet.public \
  -target=module.vpc.aws_internet_gateway.main \
  -target=module.vpc.aws_eip.nat \
  -target=module.vpc.aws_nat_gateway.main \
  -target=module.vpc.aws_route_table.private \
  -target=module.vpc.aws_route_table.public \
  -target=module.vpc.aws_route_table_association.private \
  -target=module.vpc.aws_route_table_association.public \
  -target=module.security_groups.aws_security_group.eks_cluster \
  -target=module.security_groups.aws_security_group.eks_worker_nodes \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_eks_cluster \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_eks_cluster \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_self_all \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_self_all \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_cluster_443 \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_services \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_vpc_cidr_nodeport \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_aws_apis \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_worker_nodes \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_worker_nodes \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_alb_443 \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_alb_443 \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_vpc_endpoints_443 \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_nodes_services \
  -target=module.vpc_endpoints.aws_vpc_endpoint.ecr_api \
  -target=module.vpc_endpoints.aws_vpc_endpoint.ecr_dkr \
  -target=module.vpc_endpoints.aws_vpc_endpoint.s3 \
  -target=module.vpc_endpoints.aws_vpc_endpoint.ssm \
  -target=module.vpc_endpoints.aws_vpc_endpoint.ssmmessages \
  -target=module.vpc_endpoints.aws_vpc_endpoint.ec2messages \
  -target=module.vpc_endpoints.aws_vpc_endpoint.execute_api \
  -target=module.eks.aws_cloudwatch_log_group.cluster \
  -target=module.eks.aws_eks_cluster.this \
  -target=module.eks.aws_eks_node_group.this \
  -target=module.monitoring.aws_cloudwatch_metric_alarm.cluster_cpu_utilization \
  -target=module.monitoring.aws_cloudwatch_metric_alarm.cluster_memory_utilization \
  -target=module.monitoring.aws_sns_topic.alerts \
  -target=module.monitoring.aws_sns_topic_policy.alerts \
  -target=module.api_gateway.aws_apigatewayv2_api.this \
  -target=module.api_gateway.aws_apigatewayv2_stage.this \
  -target=module.api_gateway.aws_apigatewayv2_vpc_link.this \
  -target=module.api_gateway.aws_cloudwatch_log_group.api_gateway \
  -target=module.api_gateway.aws_cloudwatch_metric_alarm.api_gateway_4xx \
  -target=module.api_gateway.aws_cloudwatch_metric_alarm.api_gateway_5xx

terraform apply tfplan

echo "Phase 2: Creating ECR repositories..."
terraform plan -out=tfplan \
  -target=module.ecr.aws_ecr_repository.api_gateway \
  -target=module.ecr.aws_ecr_repository.model_server \
  -target=module.ecr.aws_ecr_lifecycle_policy.api_gateway \
  -target=module.ecr.aws_ecr_lifecycle_policy.model_server

terraform apply tfplan

echo "Phase 3: Deploying WAF and CloudFront..."
terraform plan -out=tfplan \
  -target=module.waf.aws_wafv2_web_acl.this \
  -target=module.cloudfront.aws_cloudfront_distribution.this

terraform apply tfplan

echo "Phase 4: Applying additional security group rules..."
terraform plan -out=tfplan \
  -target=module.security_groups.aws_security_group.vpc_endpoints \
  -target=module.security_groups.aws_security_group.api_gateway \
  -target=module.security_groups.aws_security_group.alb \
  -target=module.security_groups.aws_security_group.eks_cluster \
  -target=module.security_groups.aws_security_group.eks_worker_nodes \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_worker_nodes \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_worker_nodes \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_self_all \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_self_all \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_cluster_443 \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_services \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_vpc_cidr_nodeport \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_aws_apis \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_worker_nodes \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_worker_nodes \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_alb_443 \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_alb_443 \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.cluster_ingress_vpc_endpoints_443 \
  -target=module.security_groups.aws_security_group_rule.cluster_egress_nodes_services \
  -target=module.security_groups.aws_security_group_rule.api_gateway_ingress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.api_gateway_egress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.api_gateway_ingress_vpc_endpoints_443 \
  -target=module.security_groups.aws_security_group_rule.api_gateway_egress_vpc_endpoints_443 \
  -target=module.security_groups.aws_security_group_rule.api_gateway_ingress_client_443 \
  -target=module.security_groups.aws_security_group_rule.api_gateway_egress_client_443 \
  -target=module.security_groups.aws_security_group_rule.api_gateway_ingress_client_3000 \
  -target=module.security_groups.aws_security_group_rule.api_gateway_egress_client_3000 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_ingress_vpc_cidr_443 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_egress_vpc_cidr_443 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_ingress_api_gateway_443 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_egress_api_gateway_443 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_ingress_api_gateway_3000 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_egress_api_gateway_3000 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_ingress_alb_443 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_egress_alb_443 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_ingress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.vpc_endpoints_egress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_api_gateway_3000 \
  -target=module.security_groups.aws_security_group_rule.alb_egress_api_gateway_3000 \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_api_gateway_443 \
  -target=module.security_groups.aws_security_group_rule.alb_egress_api_gateway_443 \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_vpc_endpoints_3000 \
  -target=module.security_groups.aws_security_group_rule.alb_egress_vpc_endpoints_3000 \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_vpc_endpoints_443 \
  -target=module.security_groups.aws_security_group_rule.alb_egress_vpc_endpoints_443 \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_worker_nodes_3000 \
  -target=module.security_groups.aws_security_group_rule.alb_egress_worker_nodes_3000 \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_eks_cluster \
  -target=module.security_groups.aws_security_group_rule.alb_egress_eks_cluster \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_alb_3000 \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_alb_443 \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_alb_443 \
  -target=module.security_groups.aws_security_group_rule.alb_egress_aws_apis \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_http_80 \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_alb_9443 \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_egress_alb_9443 \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_worker_nodes_9443 \
  -target=module.security_groups.aws_security_group_rule.alb_egress_worker_nodes_9443 \
  -target=module.security_groups.aws_security_group_rule.worker_nodes_ingress_control_plane_to_webhook \
  -target=module.security_groups.aws_security_group_rule.alb_ingress_worker_nodes_webhook_443 \
  -target=module.security_groups.aws_security_group_rule.alb_egress_worker_nodes_webhook_443

terraform apply tfplan

echo "Core infrastructure deployment complete!"
echo "Now run deploy-ecr-docker.bash and then deploy-kubernetes.bash to set up OIDC and ALB controller"