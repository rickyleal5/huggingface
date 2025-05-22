#!/bin/bash

# Environment variables
export ECR_REGISTRY=${ECR_REGISTRY:-""}  # Leave blank for local
export IMAGE_TAG=${IMAGE_TAG:-"stable"}
export MODEL_NAME=${MODEL_NAME:-"gpt2"}
export ENVIRONMENT=${ENVIRONMENT:-"dev"}
export PROJECT_NAME=${PROJECT_NAME:-"huggingface"}

# Clean resources
k3d cluster delete ${PROJECT_NAME} && docker rmi -f $(docker images -aq) && docker system prune -af --volumes && docker builder prune -af && docker volume prune -f

# Build images
docker build --no-cache -t ${PROJECT_NAME}-api-gateway:${IMAGE_TAG} ./gateway
docker build --no-cache -t ${PROJECT_NAME}-${MODEL_NAME}-model-server:${IMAGE_TAG} -f ./huggingface-models/models/${MODEL_NAME}/Dockerfile ./huggingface-models
docker volume create k3d-${PROJECT_NAME}-storage

# Create cluster
k3d cluster create ${PROJECT_NAME} \
  --port "3000:3000@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0" \
  --agents 1 \
  --servers 1 \
  --k3s-node-label "size=large@agent:0" \
  --k3s-arg '--kubelet-arg=eviction-hard=imagefs.available<1%,nodefs.available<1%@agent:0' \
  --k3s-arg '--kubelet-arg=max-pods=110@agent:0' \
  --k3s-arg '--kubelet-arg=eviction-minimum-reclaim=imagefs.available=500Mi,nodefs.available=500Mi@agent:0' \
  --k3s-arg '--kubelet-arg=image-gc-high-threshold=85@agent:0' \
  --k3s-arg '--kubelet-arg=image-gc-low-threshold=80@agent:0' \
  --volume /tmp/k3dvol:/var/lib/rancher/k3s/storage@all \
  --k3s-arg '--kubelet-arg=eviction-hard=nodefs.available<10Gi@agent:0'

# Import images
k3d image import huggingface-api-gateway:${IMAGE_TAG} huggingface-${MODEL_NAME}-model-server:${IMAGE_TAG} -c ${PROJECT_NAME}

# Create namespace if it doesn't exist
echo "Creating namespace..."
kubectl create namespace ${PROJECT_NAME}-${ENVIRONMENT} --dry-run=client -o yaml | kubectl apply -f -

# Apply manifests
echo "Applying manifests..."
envsubst < k8s/api-gateway-deployments/api-gateway-deployment.yaml | kubectl apply -f - -n ${PROJECT_NAME}-${ENVIRONMENT}
envsubst < k8s/api-gateway-deployments/api-gateway-local-service.yaml | kubectl apply -f - -n ${PROJECT_NAME}-${ENVIRONMENT}
envsubst < k8s/model-deployments/gpt2-deployment.yaml | kubectl apply -f - -n ${PROJECT_NAME}-${ENVIRONMENT}

# Wait for pods to be ready
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app=${PROJECT_NAME}-${ENVIRONMENT}-api-gateway -n ${PROJECT_NAME}-${ENVIRONMENT} --timeout=300s
kubectl wait --for=condition=ready pod -l app=${PROJECT_NAME}-${ENVIRONMENT}-${MODEL_NAME}-model-server -n ${PROJECT_NAME}-${ENVIRONMENT} --timeout=300s

# Wait for LoadBalancer to be ready
echo "Waiting for LoadBalancer to be ready..."
sleep 10

# Test the system
echo "Testing API Gateway health endpoint..."
curl -s http://localhost:3000/health | jq .

echo "Testing Model Server status through API Gateway..."
curl -s http://localhost:3000/models/${MODEL_NAME}/status | jq .

echo "Testing text generation..."
curl -s -X POST -H "Content-Type: application/json" \
  -d '{"text": "Hello, how are you?", "max_length": 50}' \
  http://localhost:3000/models/${MODEL_NAME}/generate | jq .

# Clean resources
# kubectl delete -f k8s/api-gateway-deployments/api-gateway-deployment.yaml,k8s/model-deployments/gpt2-deployment.yaml
# k3d cluster delete huggingface && docker rmi -f $(docker images -aq) && docker system prune -af --volumes && docker builder prune -af && docker volume prune -f
