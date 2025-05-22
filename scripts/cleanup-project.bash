#!/bin/bash
set -e  # Exit on error

# Set the environment (dev, staging, prod, etc.)
ENVIRONMENT="dev"

# Set AWS profile and region
export AWS_PROFILE=<AWS_SSO_PROFILE>
AWS_REGION="us-east-1"

# Login to AWS SSO
aws sso login --profile ${AWS_PROFILE}

# Navigate to the environment directory
cd "$(dirname "$0")/../terraform/environments/${ENVIRONMENT}"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init -reconfigure

echo "Phase 1: Checking and removing Kubernetes resources..."
# Get EKS cluster name
CLUSTER_NAME="huggingface-${ENVIRONMENT}-cluster"

# Check if cluster exists
if aws eks describe-cluster --region ${AWS_REGION} --name ${CLUSTER_NAME} 2>/dev/null; then
    echo "Cluster exists, proceeding with Kubernetes cleanup..."
    
    # Update kubeconfig
    aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}

    # Delete all deployments, statefulsets, and daemonsets
    echo "Deleting all Kubernetes workloads..."
    kubectl delete deployments --all --all-namespaces || true
    kubectl delete statefulsets --all --all-namespaces || true
    kubectl delete daemonsets --all --all-namespaces || true

    # Delete specific deployments
    echo "Removing specific deployments..."
    kubectl delete deployment huggingface-dev-gpt2-model-server -n huggingface-dev || true
    kubectl delete deployment huggingface-dev-api-gateway -n huggingface-dev || true

    # Delete network policies
    echo "Removing network policies..."
    kubectl delete networkpolicy huggingface-dev-api-gateway-network-policy -n huggingface-dev || true
    kubectl delete networkpolicy huggingface-dev-model-network-policy -n huggingface-dev || true

    # Delete all services of type LoadBalancer first
    echo "Deleting all LoadBalancer services..."
    kubectl get svc --all-namespaces -o json | jq -r '.items[] | select(.spec.type == "LoadBalancer") | .metadata.namespace + " " + .metadata.name' | while read -r ns name; do
        kubectl delete svc "$name" -n "$ns" || true
    done

    # Delete the AWS Load Balancer Controller and related resources
    echo "Removing AWS Load Balancer Controller..."
    helm uninstall aws-load-balancer-controller -n kube-system || true

    # Delete the webhook configuration
    echo "Removing webhook configuration..."
    kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook || true

    # Delete the webhook service
    echo "Removing webhook service..."
    kubectl delete svc aws-load-balancer-webhook-service -n kube-system || true

    # Wait for resources to be cleaned up
    echo "Waiting for Kubernetes resources to be cleaned up..."
    sleep 30
else
    echo "Cluster does not exist, skipping Kubernetes cleanup..."
fi

echo "Phase 2: Cleaning up AWS resources..."
# Refresh terraform state to ensure outputs are available
echo "Refreshing terraform state..."
terraform refresh || true

# Get VPC ID from terraform output
echo "Getting VPC ID from terraform output..."
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")

if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    echo "Found VPC ID from terraform: $VPC_ID"
    
    # First, get all target groups in the VPC
    echo "Getting all target groups in VPC..."
    
    # Get target groups with huggingface tags
    TG_ARNS=$(aws elbv2 describe-target-groups \
        --query "TargetGroups[?VpcId=='${VPC_ID}']" \
        --output json | jq -r '.[] | select(.TargetGroupName | contains("huggingface") or contains("huggingf-huggingf") or startswith("k8s-huggingf")) | .TargetGroupArn')
    
    if [ ! -z "$TG_ARNS" ]; then
        echo "Found target groups to delete:"
        echo "$TG_ARNS"
        echo "$TG_ARNS" | tr '\t' '\n' | while read -r tg_arn; do
            if [ ! -z "$tg_arn" ]; then
                echo "Deleting target group: $tg_arn"
                aws elbv2 delete-target-group --target-group-arn "$tg_arn" || true
            fi
        done
        
        # Wait for target groups to be deleted
        echo "Waiting for target groups to be deleted..."
        sleep 30
    else
        echo "No target groups found in VPC"
    fi
    
    # Then get all ALBs in the VPC that are part of the huggingface project
    ALB_ARNS=$(aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?VpcId=='${VPC_ID}']" \
        --output json | jq -r '.[] | select(.LoadBalancerName | contains("huggingface") or contains("huggingf")) | .LoadBalancerArn')
    
    if [ ! -z "$ALB_ARNS" ]; then
        echo "$ALB_ARNS" | tr '\t' '\n' | while read -r alb_arn; do
            if [ ! -z "$alb_arn" ]; then
                echo "Processing ALB: $alb_arn"
                
                # First, delete all listeners
                echo "Deleting listeners for ALB: $alb_arn"
                LISTENER_ARNS=$(aws elbv2 describe-listeners \
                    --load-balancer-arn "$alb_arn" \
                    --query 'Listeners[*].ListenerArn' \
                    --output text)
                
                if [ ! -z "$LISTENER_ARNS" ]; then
                    echo "$LISTENER_ARNS" | tr '\t' '\n' | while read -r listener_arn; do
                        if [ ! -z "$listener_arn" ]; then
                            echo "Deleting listener: $listener_arn"
                            aws elbv2 delete-listener --listener-arn "$listener_arn" || true
                        fi
                    done
                    
                    # Wait for listeners to be deleted
                    echo "Waiting for listeners to be deleted..."
                    sleep 30
                fi
                
                # Finally, delete the ALB
                echo "Deleting ALB: $alb_arn"
                aws elbv2 delete-load-balancer --load-balancer-arn "$alb_arn" || true
                
                # Wait for ALB to be deleted
                echo "Waiting for ALB to be deleted..."
                MAX_RETRIES=30
                RETRY_COUNT=0
                while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                    if ! aws elbv2 describe-load-balancers --load-balancer-arns "$alb_arn" 2>/dev/null; then
                        echo "ALB $alb_arn successfully deleted"
                        break
                    fi
                    echo "ALB still exists, waiting... (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
                    sleep 30
                    RETRY_COUNT=$((RETRY_COUNT + 1))
                done
                
                if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
                    echo "Warning: ALB $alb_arn still exists after maximum retries"
                fi
            fi
        done
    else
        echo "No ALBs found in VPC"
    fi
    
    # Clean up any orphaned ENIs
    echo "Cleaning up orphaned ENIs..."
    ENI_IDS=$(aws ec2 describe-network-interfaces \
        --filters "Name=vpc-id,Values=${VPC_ID}" \
        --query 'NetworkInterfaces[?Attachment==null].[NetworkInterfaceId]' \
        --output text)
    
    if [ ! -z "$ENI_IDS" ]; then
        echo "$ENI_IDS" | tr '\t' '\n' | while read -r eni_id; do
            if [ ! -z "$eni_id" ]; then
                echo "Deleting ENI: $eni_id"
                aws ec2 delete-network-interface --network-interface-id "$eni_id" || true
            fi
        done
    fi
    
    # Wait for any remaining ALBs to be fully deleted
    echo "Waiting for any remaining ALBs to be fully deleted..."
    sleep 60
else
    echo "VPC ID not found in terraform outputs - VPC may have been already deleted"
    echo "Skipping VPC-dependent cleanup..."
fi

echo "Phase 3: Cleaning up specific ECR images..."
# List of specific images to clean
IMAGES=(
    "api-gateway"
    "gpt2-model-server"
)

for IMAGE in "${IMAGES[@]}"; do
    echo "Cleaning up image: $IMAGE"
    
    # Check if repository exists
    if aws ecr describe-repositories --repository-names "$IMAGE" 2>/dev/null; then
        # Get all image digests
        echo "Getting image digests for repository: $IMAGE"
        IMAGE_IDS=$(aws ecr list-images --repository-name "$IMAGE" --query 'imageIds[*]' --output json)
        
        if [ ! -z "$IMAGE_IDS" ] && [ "$IMAGE_IDS" != "[]" ]; then
            echo "Deleting all images from repository: $IMAGE"
            # Delete all images using the image IDs
            aws ecr batch-delete-image --repository-name "$IMAGE" --image-ids "$IMAGE_IDS" || true
            echo "Images deleted from repository: $IMAGE"
        else
            echo "No images found in repository: $IMAGE"
        fi
    else
        echo "Repository $IMAGE does not exist, skipping..."
    fi
done

echo "Phase 4: Destroying Terraform resources..."
# First, destroy resources that might have dependencies
echo "Destroying resources with potential dependencies..."
terraform destroy -target=module.cloudfront -auto-approve || true
terraform destroy -target=module.waf -auto-approve || true
terraform destroy -target=module.api_gateway -auto-approve || true
terraform destroy -target=module.monitoring -auto-approve || true

# Wait for resources to be destroyed
echo "Waiting for resources to be destroyed..."
sleep 30

# Destroy the EKS cluster and related resources
echo "Destroying EKS cluster and related resources..."
terraform destroy -target=module.eks -auto-approve || true

# Wait for EKS cluster to be destroyed
echo "Waiting for EKS cluster to be destroyed..."
sleep 60

# Destroy IAM roles and policies
echo "Destroying IAM roles and policies..."
terraform destroy -target=module.iam -auto-approve || true

# Destroy ECR repositories
echo "Destroying ECR repositories..."
terraform destroy -target=module.ecr -auto-approve || true

# Destroy VPC endpoints
echo "Destroying VPC endpoints..."
terraform destroy -target=module.vpc_endpoints -auto-approve || true

# Destroy security groups
echo "Destroying security groups..."
terraform destroy -target=module.security_groups -auto-approve || true

# Destroy NAT Gateways explicitly
echo "Destroying NAT Gateways..."
terraform destroy -target=module.vpc.aws_nat_gateway.this -auto-approve || true

# Wait for NAT Gateways to be destroyed
echo "Waiting for NAT Gateways to be destroyed..."
sleep 60

# Destroy the VPC (which includes remaining VPC resources)
echo "Destroying VPC and remaining resources..."
terraform destroy -target=module.vpc -auto-approve || true

# Final cleanup of any remaining resources
echo "Performing final cleanup..."
terraform destroy -auto-approve || true

echo "Project destroyed successfully!" 