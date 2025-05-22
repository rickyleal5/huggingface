#!/bin/bash
set -e  # Exit on error

export AWS_PROFILE=<AWS_SSO_PROFILE>
IMAGE_TAG="stable"
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="<YOUR-AWS-ACCOUNT-ID>"

# Login to AWS SSO
aws sso login --profile ${AWS_PROFILE}

# Define repository names (environment-agnostic)
MODEL_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/huggingface-gpt2-model-server"
GATEWAY_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/huggingface-api-gateway"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build images
echo "Building Docker images..."
docker build -t huggingface-api-gateway:${IMAGE_TAG} ./gateway
docker build -t huggingface-gpt2-model-server:${IMAGE_TAG} -f ./huggingface-models/models/gpt2/Dockerfile ./huggingface-models

# Tag images
echo "Tagging images..."
docker tag huggingface-api-gateway:${IMAGE_TAG} ${GATEWAY_REPO}:${IMAGE_TAG}
docker tag huggingface-gpt2-model-server:${IMAGE_TAG} ${MODEL_REPO}:${IMAGE_TAG}

# Push images
echo "Pushing images to ECR..."
docker push ${GATEWAY_REPO}:${IMAGE_TAG}
docker push ${MODEL_REPO}:${IMAGE_TAG}

echo "Successfully pushed images to ECR repositories"
