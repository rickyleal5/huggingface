#!/bin/bash
set -e  # Exit on error

# Function to check and install required tools
check_required_tools() {
    local tools=("aws" "kubectl" "helm")
    local missing_tools=()

    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=($tool)
        fi
    done

    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo "The following required tools are missing: ${missing_tools[*]}"
        echo "Installing missing tools..."
        
        # Update package list
        sudo apt-get update

        # Install AWS CLI if missing
        if [[ " ${missing_tools[*]} " =~ " aws " ]]; then
            echo "Installing AWS CLI..."
            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            unzip awscliv2.zip
            sudo ./aws/install
            rm -rf aws awscliv2.zip
        fi

        # Install kubectl if missing
        if [[ " ${missing_tools[*]} " =~ " kubectl " ]]; then
            echo "Installing kubectl..."
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
            rm kubectl
        fi

        # Install helm if missing
        if [[ " ${missing_tools[*]} " =~ " helm " ]]; then
            echo "Installing helm..."
            curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
        fi
    fi
}

# Function to verify AWS resources
verify_aws_resources() {
    echo "Verifying AWS resources..."
    
    # Verify VPC endpoints if using private subnets
    echo "Verifying VPC endpoints..."
    aws ec2 describe-vpc-endpoints \
        --filters "Name=vpc-id,Values=${VPC_ID}" \
        --query 'VpcEndpoints[*].{Service:ServiceName,State:State}' \
        --output json | cat

    # Verify security groups
    echo "Verifying security group configurations..."
    echo "API Gateway security group:"
    aws ec2 describe-security-groups \
        --group-ids ${API_GATEWAY_SECURITY_GROUP_ID} \
        --query 'SecurityGroups[*].{Name:GroupName,Id:GroupId}' \
        --output json | cat
    
    echo "ALB security group:"
    aws ec2 describe-security-groups \
        --group-ids ${ALB_SECURITY_GROUP_ID} \
        --query 'SecurityGroups[*].{Name:GroupName,Id:GroupId}' \
        --output json | cat
    
    echo "EKS Cluster security group:"
    aws ec2 describe-security-groups \
        --group-ids ${EKS_CLUSTER_SECURITY_GROUP_ID} \
        --query 'SecurityGroups[*].{Name:GroupName,Id:GroupId}' \
        --output json | cat
}

# Function to wait for target group health
wait_for_target_group_health() {
    local max_retries=30
    local retry_count=0
    local target_group_arn=$1

    echo "Waiting for target group to be healthy..."
    while [ $retry_count -lt $max_retries ]; do
        health_status=$(aws elbv2 describe-target-health \
            --target-group-arn ${target_group_arn} \
            --query 'TargetHealthDescriptions[*].TargetHealth.State' \
            --output text)
        
        if [[ $health_status == *"healthy"* ]]; then
            echo "Target group is healthy!"
            return 0
        fi
        
        echo "Target group not yet healthy, retrying in 10 seconds... (attempt $((retry_count + 1))/$max_retries)"
        retry_count=$((retry_count + 1))
        sleep 10
    done

    echo "Error: Target group did not become healthy after $max_retries attempts"
    return 1
}

# Check and install required tools
check_required_tools

# Set environment variables
export AWS_PROFILE=<AWS_SSO_PROFILE>
export ENVIRONMENT="dev"
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="<YOUR-AWS-ACCOUNT-ID>"
export PROJECT_NAME="huggingface"
export CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}-cluster"
export NAMESPACE="${PROJECT_NAME}-${ENVIRONMENT}"
export VALIDATE=${VALIDATE:-"false"}  # Default to false, can be overridden by setting VALIDATE=true
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/"

# Get VPC and security group IDs from Terraform output
echo "Getting VPC and security group IDs..."
cd "$(dirname "$0")/../terraform/environments/${ENVIRONMENT}"
export VPC_ID=$(terraform output -raw vpc_id)
export VPC_CIDR=$(terraform output -raw vpc_cidr)
export API_GATEWAY_SECURITY_GROUP_ID=$(terraform output -raw api_gateway_security_group_id)
export ALB_SECURITY_GROUP_ID=$(terraform output -raw alb_security_group_id)
export EKS_CLUSTER_SECURITY_GROUP_ID=$(terraform output -raw eks_cluster_security_group_id)
cd - > /dev/null

if [ -z "$VPC_ID" ] || [ -z "$VPC_CIDR" ] || [ -z "$API_GATEWAY_SECURITY_GROUP_ID" ] || [ -z "$ALB_SECURITY_GROUP_ID" ] || [ -z "$EKS_CLUSTER_SECURITY_GROUP_ID" ]; then
    echo "Error: Could not find one or more required values from Terraform output"
    exit 1
fi

# Set kubectl validation flag
VALIDATE_FLAG=""
if [ "$VALIDATE" = "false" ]; then
    VALIDATE_FLAG="--validate=false"
fi

# Login to AWS SSO
aws sso login --profile ${AWS_PROFILE}

# Get EKS cluster credentials
echo "Getting EKS cluster credentials..."
aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}

# Create namespace if it doesn't exist
echo "Creating namespace..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f - ${VALIDATE_FLAG}

# Set up OIDC provider for the cluster
echo "Setting up OIDC provider for the cluster..."
MAX_RETRIES=5
RETRY_COUNT=0
OIDC_ID=""

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    OIDC_ID=$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
    if [ ! -z "$OIDC_ID" ]; then
        break
    fi
    echo "Waiting for OIDC ID to be available... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 10
done

if [ -z "$OIDC_ID" ]; then
    echo "Error: Could not get OIDC ID after $MAX_RETRIES attempts"
    exit 1
fi

# Get OIDC thumbprint
echo "Getting OIDC thumbprint..."
OIDC_ISSUER_URL="oidc.eks.${AWS_REGION}.amazonaws.com"
OIDC_THUMBPRINT=$(echo | openssl s_client -servername ${OIDC_ISSUER_URL} -showcerts -connect ${OIDC_ISSUER_URL}:443 2>/dev/null | openssl x509 -fingerprint -sha1 -noout | cut -d= -f2 | tr -d ':' | tr '[:upper:]' '[:lower:]')

if [ -z "$OIDC_THUMBPRINT" ]; then
    echo "Error: Could not get OIDC thumbprint"
    exit 1
fi

# Apply OIDC-dependent Terraform resources
echo "Applying OIDC-dependent Terraform resources..."
cd "$(dirname "$0")/../terraform/environments/${ENVIRONMENT}"
terraform plan -out=tfplan \
  -var="alb_listener_arn=" \
  -var="cluster_oidc_issuer_url=https://oidc.eks.${AWS_REGION}.amazonaws.com/id/${OIDC_ID}" \
  -var="cluster_oidc_thumbprint=${OIDC_THUMBPRINT}" \
  -target=module.iam.aws_iam_openid_connect_provider.eks \
  -target=module.iam.aws_iam_role.aws_load_balancer_controller \
  -target=module.iam.aws_iam_role_policy_attachment.aws_load_balancer_controller \
  -target=module.iam.aws_iam_role.flow_logs \
  -target=module.iam.aws_iam_role_policy.flow_logs \
  -target=module.vpc.aws_flow_log.main
terraform apply tfplan

# Get the Load Balancer Controller role ARN
export LOAD_BALANCER_CONTROLLER_ROLE_ARN=$(terraform output -raw load_balancer_controller_role_arn)
cd - > /dev/null

if [ -z "$LOAD_BALANCER_CONTROLLER_ROLE_ARN" ]; then
    echo "Error: Could not find Load Balancer Controller role ARN from Terraform output"
    exit 1
fi

# Wait for OIDC provider to be fully propagated
echo "Waiting for OIDC provider to be fully propagated..."
sleep 30

# Set all required environment variables for Kubernetes manifests
echo "Setting up environment variables for Kubernetes manifests..."
export ENVIRONMENT=${ENVIRONMENT}
export NAMESPACE=${NAMESPACE}
export ECR_REGISTRY=${ECR_REGISTRY}
export cluster_name=${CLUSTER_NAME}
export load_balancer_controller_role_arn=${LOAD_BALANCER_CONTROLLER_ROLE_ARN}

# Verify AWS resources
verify_aws_resources

# Install AWS Load Balancer Controller using Helm
echo "Installing AWS Load Balancer Controller using Helm..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install or upgrade the controller
if ! helm status aws-load-balancer-controller -n kube-system &> /dev/null; then
    echo "Installing AWS Load Balancer Controller..."
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=${CLUSTER_NAME} \
        --set serviceAccount.create=true \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${LOAD_BALANCER_CONTROLLER_ROLE_ARN} \
        --set region=${AWS_REGION} \
        --set vpcId=${VPC_ID}
else
    echo "Updating AWS Load Balancer Controller..."
    helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=${CLUSTER_NAME} \
        --set serviceAccount.create=true \
        --set serviceAccount.name=aws-load-balancer-controller \
        --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${LOAD_BALANCER_CONTROLLER_ROLE_ARN} \
        --set region=${AWS_REGION} \
        --set vpcId=${VPC_ID}
fi

# Wait for AWS Load Balancer Controller to be ready
echo "Waiting for AWS Load Balancer Controller to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

# Wait for controller to be fully operational
echo "Waiting for AWS Load Balancer Controller to be fully operational..."
sleep 90  # Increased from 60 to 90 seconds to ensure controller is fully operational

# Apply Network Policies first
echo "Applying Network Policies..."
echo "Applying API Gateway Network Policy..."
envsubst < k8s/api-gateway-deployments/network-policy.yaml | kubectl apply -n ${NAMESPACE} -f - ${VALIDATE_FLAG}
echo "Applying Model Server Network Policy..."
envsubst < k8s/model-deployments/model-network-policy.yaml | kubectl apply -n ${NAMESPACE} -f - ${VALIDATE_FLAG}

# Apply Model deployments first (since API Gateway depends on it)
echo "Applying Model deployments..."
envsubst < k8s/model-deployments/gpt2-deployment.yaml | kubectl apply -n ${NAMESPACE} -f - ${VALIDATE_FLAG}

# Wait for model server to be ready (increased timeout due to longer initial delay)
echo "Waiting for model server to be ready..."
kubectl wait -n ${NAMESPACE} --for=condition=available --timeout=600s deployment/${PROJECT_NAME}-${ENVIRONMENT}-gpt2-model-server

# Apply API Gateway deployment
echo "Applying API Gateway deployment..."
envsubst < k8s/api-gateway-deployments/api-gateway-deployment.yaml | kubectl apply -n ${NAMESPACE} -f - ${VALIDATE_FLAG}

# Apply API Gateway Ingress
echo "Applying API Gateway Ingress..."
envsubst < k8s/api-gateway-deployments/api-gateway-ingress.yaml | kubectl apply -n ${NAMESPACE} -f - ${VALIDATE_FLAG}

# Wait for API Gateway to be ready
echo "Waiting for API Gateway to be ready..."
kubectl wait -n ${NAMESPACE} --for=condition=available --timeout=300s deployment/${PROJECT_NAME}-${ENVIRONMENT}-api-gateway

# Wait for ALB to be created by the AWS Load Balancer Controller
echo "Waiting for ALB to be created..."
MAX_RETRIES=10
RETRY_COUNT=0
ALB_ARN=""

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    ALB_ARN=$(aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?contains(LoadBalancerName, 'huggingfacedev')].LoadBalancerArn" \
        --output text)
    
    if [ ! -z "$ALB_ARN" ]; then
        break
    fi
    
    echo "Waiting for ALB to be created... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 30
done

if [ -z "$ALB_ARN" ]; then
    echo "Error: Could not find ALB ARN after $MAX_RETRIES attempts"
    exit 1
fi

# Verify the ALB is internal (not internet-facing)
echo "Verifying ALB is internal..."
ALB_SCHEME=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns ${ALB_ARN} \
    --query "LoadBalancers[0].Scheme" \
    --output text)

if [ "$ALB_SCHEME" != "internal" ]; then
    echo "Warning: ALB is not internal (${ALB_SCHEME}). It should be internal for proper Client Request Flow."
    echo "Check your Ingress annotations to ensure alb.ingress.kubernetes.io/scheme: internal is set."
else
    echo "ALB is correctly configured as internal."
fi

# Get the ALB listener ARN
echo "Getting ALB listener ARN..."
export ALB_LISTENER_ARN=$(aws elbv2 describe-listeners \
    --load-balancer-arn ${ALB_ARN} \
    --query "Listeners[0].ListenerArn" \
    --output text)

if [ -z "$ALB_LISTENER_ARN" ]; then
    echo "Error: Could not find ALB listener ARN"
    exit 1
fi

echo "ALB Listener ARN: ${ALB_LISTENER_ARN}"

# Get target group ARN
echo "Getting target group ARN..."
export TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
    --load-balancer-arn ${ALB_ARN} \
    --query "TargetGroups[0].TargetGroupArn" \
    --output text)

if [ -z "$TARGET_GROUP_ARN" ]; then
    echo "Error: Could not find target group ARN"
    exit 1
fi

# Wait for target group to be healthy
wait_for_target_group_health ${TARGET_GROUP_ARN}

# Update API Gateway integration with ALB listener
echo "Updating API Gateway integration with ALB listener..."
cd "$(dirname "$0")/../terraform/environments/${ENVIRONMENT}"
terraform apply -var="alb_listener_arn=${ALB_LISTENER_ARN}" -auto-approve
cd - > /dev/null

# Get the API Gateway endpoint after it's created
echo "Getting API Gateway endpoint..."
cd "$(dirname "$0")/../terraform/environments/${ENVIRONMENT}"
export API_ENDPOINT=$(terraform output -raw api_gateway_endpoint)
cd - > /dev/null

if [ -z "$API_ENDPOINT" ]; then
    echo "Error: Could not find API Gateway endpoint"
    exit 1
fi

# Wait additional time for DNS propagation and health checks
echo "Waiting for DNS propagation and health checks..."
sleep 120

# Test all API Gateway routes
echo -e "\nTesting all API Gateway routes..."

# Test health endpoint
echo -e "\nTesting health endpoint..."
MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s --max-time 30 ${API_ENDPOINT}/health; then
        echo "Health check successful!"
        break
    fi
    echo "Health check failed, retrying in 15 seconds... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 15
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Error: Health check failed after $MAX_RETRIES attempts"
    exit 1
fi

# Test model status endpoint
echo -e "\nTesting model status endpoint..."
MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s --max-time 30 ${API_ENDPOINT}/models/gpt2/status; then
        echo "Model status check successful!"
        break
    fi
    echo "Model status check failed, retrying in 15 seconds... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 15
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Error: Model status check failed after $MAX_RETRIES attempts"
    exit 1
fi

# Test model generation endpoint
echo -e "\nTesting model generation endpoint..."
MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -X POST ${API_ENDPOINT}/models/gpt2/generate \
        -H "Content-Type: application/json" \
        -d '{"text": "Hello, how are you?", "max_length": 50}' \
        --max-time 60; then
        echo "Model generation successful!"
        break
    fi
    echo "Model generation failed, retrying in 15 seconds... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 15
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Error: Model generation failed after $MAX_RETRIES attempts"
    exit 1
fi

echo -e "\nAll API Gateway routes tested successfully!"
echo -e "\nKubernetes deployment completed successfully!" 