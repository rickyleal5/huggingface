#!/bin/bash
set -e  # Exit on error

# Set the environment (dev, staging, prod, etc.)
ENVIRONMENT="dev"

# Set AWS profile and region
export AWS_PROFILE=<AWS_SSO_PROFILE>
AWS_REGION="us-east-1"
CLUSTER_NAME="huggingface-${ENVIRONMENT}-cluster"

# Login to AWS SSO
aws sso login --profile ${AWS_PROFILE}

echo "Cleaning up Load Balancer Controller and related resources..."

# Update kubeconfig
aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}

# Delete the Load Balancer Controller
echo "Removing AWS Load Balancer Controller..."
helm uninstall aws-load-balancer-controller -n kube-system || true

# Delete the webhook configuration
echo "Removing webhook configuration..."
kubectl delete validatingwebhookconfiguration aws-load-balancer-webhook || true

# Delete the webhook service
echo "Removing webhook service..."
kubectl delete svc aws-load-balancer-webhook-service -n kube-system || true

# Delete the deployments
echo "Removing deployments..."
kubectl delete deployment huggingface-dev-gpt2-model-server -n huggingface-dev || true
kubectl delete deployment huggingface-dev-api-gateway -n huggingface-dev || true

# Delete the network policies
echo "Removing network policies..."
kubectl delete networkpolicy huggingface-dev-api-gateway-network-policy -n huggingface-dev || true
kubectl delete networkpolicy huggingface-dev-model-network-policy -n huggingface-dev || true

# Get and delete the ALB if it exists
echo "Removing ALB and target groups..."
ALB_ARN=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?contains(LoadBalancerName, 'huggingfacedev')].LoadBalancerArn" \
    --output text)

if [ ! -z "$ALB_ARN" ]; then
    # Get the target group ARN
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
        --load-balancer-arn ${ALB_ARN} \
        --query "TargetGroups[0].TargetGroupArn" \
        --output text)
    
    # Delete the target group
    if [ ! -z "$TARGET_GROUP_ARN" ]; then
        echo "Deleting target group..."
        aws elbv2 delete-target-group --target-group-arn ${TARGET_GROUP_ARN}
    fi
    
    # Delete the ALB
    echo "Deleting ALB..."
    aws elbv2 delete-load-balancer --load-balancer-arn ${ALB_ARN}
fi

echo "Cleanup completed! You can now run deploy-kubernetes.bash again." 