# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name_prefix}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc-endpoints-sg"
    }
  )
}

# Security Group for API Gateway
resource "aws_security_group" "api_gateway" {
  name        = "${var.name_prefix}-api-gateway-sg"
  description = "Security group for API Gateway"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-api-gateway-sg"
    }
  )
}

# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb-sg"
    }
  )
}

# Security Group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name        = "${var.name_prefix}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-cluster-sg"
    }
  )
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_worker_nodes" {
  name        = "${var.name_prefix}-eks-worker-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-eks-worker-nodes-sg"
    }
  )
}

####################
# Security Group Rules - API Gateway
####################

resource "aws_security_group_rule" "api_gateway_ingress_alb_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.api_gateway.id
  description              = "Allow inbound traffic from ALB on port 3000"
}

resource "aws_security_group_rule" "api_gateway_egress_alb_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.api_gateway.id
  description              = "Allow outbound traffic to ALB on port 3000"
}

resource "aws_security_group_rule" "api_gateway_ingress_vpc_endpoints_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.api_gateway.id
  description              = "Allow inbound traffic from VPC endpoints on port 443"
}

resource "aws_security_group_rule" "api_gateway_egress_vpc_endpoints_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.api_gateway.id
  description              = "Allow outbound traffic to VPC endpoints on port 443"
}

resource "aws_security_group_rule" "api_gateway_ingress_client_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.api_gateway.id
  description       = "Allow inbound traffic from client on port 443"
}

resource "aws_security_group_rule" "api_gateway_egress_client_443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.api_gateway.id
  description       = "Allow outbound traffic to client on port 443"
}

resource "aws_security_group_rule" "api_gateway_ingress_client_3000" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.api_gateway.id
  description       = "Allow inbound traffic from client on port 3000"
}

resource "aws_security_group_rule" "api_gateway_egress_client_3000" {
  type              = "egress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.api_gateway.id
  description       = "Allow outbound traffic to client on port 3000"
}

####################
# Security Group Rules - VPC Endpoints
####################

resource "aws_security_group_rule" "vpc_endpoints_ingress_vpc_cidr_443" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow inbound HTTPS traffic from VPC"
}

resource "aws_security_group_rule" "vpc_endpoints_egress_vpc_cidr_443" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.vpc_endpoints.id
  description       = "Allow outbound HTTPS traffic to VPC"
}

resource "aws_security_group_rule" "vpc_endpoints_ingress_api_gateway_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_gateway.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow inbound HTTPS traffic from API Gateway"
}

resource "aws_security_group_rule" "vpc_endpoints_egress_api_gateway_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_gateway.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow outbound HTTPS traffic to API Gateway"
}

resource "aws_security_group_rule" "vpc_endpoints_ingress_api_gateway_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_gateway.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow inbound HTTPS traffic from API Gateway"
}

resource "aws_security_group_rule" "vpc_endpoints_egress_api_gateway_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_gateway.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow outbound HTTPS traffic to API Gateway"
}

resource "aws_security_group_rule" "vpc_endpoints_ingress_alb_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow inbound HTTPS traffic from ALB"
}

resource "aws_security_group_rule" "vpc_endpoints_egress_alb_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow outbound HTTPS traffic to ALB"
}

resource "aws_security_group_rule" "vpc_endpoints_ingress_alb_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow inbound HTTPS traffic from ALB"
}

resource "aws_security_group_rule" "vpc_endpoints_egress_alb_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.vpc_endpoints.id
  description              = "Allow outbound HTTPS traffic to ALB"
}

####################
# Security Group Rules - ALB
####################

resource "aws_security_group_rule" "alb_ingress_api_gateway_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_gateway.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow inbound traffic from API Gateway on port 3000"
}

resource "aws_security_group_rule" "alb_egress_api_gateway_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_gateway.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to API Gateway on port 3000"
}

resource "aws_security_group_rule" "alb_ingress_api_gateway_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_gateway.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow inbound traffic from API Gateway on port 443"
}

resource "aws_security_group_rule" "alb_egress_api_gateway_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.api_gateway.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to API Gateway on port 443"
}

resource "aws_security_group_rule" "alb_ingress_vpc_endpoints_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow inbound traffic from VPC endpoints on port 3000"
}

resource "aws_security_group_rule" "alb_egress_vpc_endpoints_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to VPC endpoints on port 3000"
}

resource "aws_security_group_rule" "alb_ingress_vpc_endpoints_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow inbound traffic from VPC endpoints on port 443"
}

resource "aws_security_group_rule" "alb_egress_vpc_endpoints_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to VPC endpoints on port 443"
}

resource "aws_security_group_rule" "alb_ingress_worker_nodes_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow inbound traffic from worker nodes on port 3000 for worker node responses"
}

resource "aws_security_group_rule" "alb_egress_worker_nodes_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to worker nodes for worker node requests"
}

# Add bidirectional communication between ALB and EKS cluster
resource "aws_security_group_rule" "alb_ingress_eks_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow inbound traffic from EKS cluster"
}

# Add bidirectional communication between ALB and EKS cluster
resource "aws_security_group_rule" "alb_egress_eks_cluster" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to EKS cluster"
}

resource "aws_security_group_rule" "alb_egress_aws_apis" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow Load Balancer Controller to call AWS APIs"
}

resource "aws_security_group_rule" "alb_ingress_http_80" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
  description       = "Allow inbound HTTP traffic to ALB"
}

# ALB Ingress from Worker Nodes (9443)
resource "aws_security_group_rule" "alb_ingress_worker_nodes_9443" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow inbound traffic from worker nodes for AWS Load Balancer Controller webhook"
}

# ALB Egress to Worker Nodes (9443)
resource "aws_security_group_rule" "alb_egress_worker_nodes_9443" {
  type                     = "egress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to worker nodes for AWS Load Balancer Controller webhook"
}

# ALB Ingress from Worker Nodes (443 for webhook)
resource "aws_security_group_rule" "alb_ingress_worker_nodes_webhook_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow inbound traffic from worker nodes for AWS Load Balancer Controller webhook service"
}

# ALB Egress to Worker Nodes (443 for webhook)
resource "aws_security_group_rule" "alb_egress_worker_nodes_webhook_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow outbound traffic to worker nodes for AWS Load Balancer Controller webhook service"
}

####################
# Security Group Rules - Worker Nodes
####################

resource "aws_security_group_rule" "worker_nodes_ingress_eks_cluster" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow EKS cluster to reach worker nodes"
}

resource "aws_security_group_rule" "worker_nodes_egress_eks_cluster" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow worker nodes to connect to EKS cluster"
}

# Worker Node SG Ingress from Worker Node SG (All)
resource "aws_security_group_rule" "worker_nodes_ingress_self_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_worker_nodes.id
  description       = "Allow inter-node communication (pods, kubelet, etc.)"
}

# Worker Node SG Egress to Worker SG (All)
resource "aws_security_group_rule" "worker_nodes_egress_self_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.eks_worker_nodes.id
  description       = "Allow inter-node communication (pods, kubelet, etc.)"
}

# Worker Node SG Ingress from ALB (3000)
resource "aws_security_group_rule" "worker_nodes_ingress_alb_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow inbound traffic from ALB on port 3000"
}

# Worker Node SG Egress to ALB (3000)
resource "aws_security_group_rule" "worker_nodes_egress_alb_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow outbound traffic to ALB on port 3000"
}

# Worker Node SG Ingress from ALB (443)
resource "aws_security_group_rule" "worker_nodes_ingress_alb_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow inbound traffic from ALB on port 443"
}

# Worker Node SG Egress to ALB (443)
resource "aws_security_group_rule" "worker_nodes_egress_alb_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow outbound traffic to ALB on port 443"
}

resource "aws_security_group_rule" "worker_nodes_ingress_cluster_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow API server to reach kubelets"
}

resource "aws_security_group_rule" "worker_nodes_egress_services" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_worker_nodes.id
  description       = "General node access (e.g., to pull images, sync, etc.)"
}

resource "aws_security_group_rule" "worker_nodes_ingress_vpc_cidr_nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.eks_worker_nodes.id
  description       = "Allow Load Balancers to reach NodePort services"
}

resource "aws_security_group_rule" "worker_nodes_egress_aws_apis" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_worker_nodes.id
  description       = "Allow worker nodes to call AWS APIs"
}

# Worker Node SG Ingress from ALB (9443)
resource "aws_security_group_rule" "worker_nodes_ingress_alb_9443" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow inbound traffic from ALB for AWS Load Balancer Controller webhook"
}

# Worker Node SG Egress to ALB (9443)
resource "aws_security_group_rule" "worker_nodes_egress_alb_9443" {
  type                     = "egress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow outbound traffic to ALB for AWS Load Balancer Controller webhook"
}

resource "aws_security_group_rule" "worker_nodes_ingress_control_plane_to_webhook" {
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster.id
  security_group_id        = aws_security_group.eks_worker_nodes.id
  description              = "Allow EKS control plane to call ALB Controller webhook"
}

####################
# Security Group Rules - EKS Cluster
####################

# Cluster SG Ingress from Worker Node SG (All)
resource "aws_security_group_rule" "cluster_ingress_worker_nodes" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow worker kubelets to connect to API server"
}

# Cluster SG Egress to Worker Node SG (All)
resource "aws_security_group_rule" "cluster_egress_worker_nodes" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_worker_nodes.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow API server to reach worker nodes"
}

resource "aws_security_group_rule" "cluster_egress_alb_443" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow outbound HTTPS traffic to ALB on port 443"
}

# EKS Cluster Rules
resource "aws_security_group_rule" "cluster_ingress_alb_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow inbound HTTPS traffic from ALB on port 443"
}

resource "aws_security_group_rule" "cluster_egress_alb_3000" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow outbound HTTPS traffic to ALB on port 3000"
}

# EKS Cluster Rules
resource "aws_security_group_rule" "cluster_ingress_alb_3000" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow inbound HTTPS traffic from ALB on port 3000"
}

# Port 443 from VPC Endpoint Security Group (API Gateway access)
resource "aws_security_group_rule" "cluster_ingress_vpc_endpoints_443" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_endpoints.id
  security_group_id        = aws_security_group.eks_cluster.id
  description              = "Allow control plane to reach API Gateway"
}

# All ports (control plane to nodes/services)
resource "aws_security_group_rule" "cluster_egress_nodes_services" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster.id
  description       = "Allow control plane to reach nodes/services"
}