# 🤗 Hugging Face Model Serving Platform

This project provides a scalable platform for serving Hugging Face models using a modern microservices architecture. The platform is built with the following key technologies:

- **Backend Services**:
  - Node.js API Gateway (TypeScript) for request routing and load balancing
  - FastAPI Model Servers for efficient model inference
  - Hugging Face Transformers for model serving

- **Infrastructure**:
  - AWS EKS for container orchestration
  - AWS ECR for container registry
  - AWS VPC for networking
  - AWS API Gateway for HTTPS endpoints
  - AWS Load Balancer Controller for traffic management
  - AWS WAF for security
  - AWS CloudFront for content delivery and caching
  - AWS CloudWatch for monitoring

- **Development & Deployment**:
  - Docker for containerization
  - Kubernetes for orchestration
  - Terraform for infrastructure as code
  - GitHub Actions for CI/CD
  - k3d for local development
  - Helm for Kubernetes package management

The platform supports both local development using k3d and production deployment on AWS EKS, with features including:
- Automatic scaling based on demand
- Load balancing across model instances
- Rate limiting and security controls
- Health monitoring and logging
- SSL/TLS encryption
- OIDC-based authentication
- Infrastructure as Code (IaC)

## Table of Contents
- [Architecture](#architecture)
- [Architecture Decisions and Cost Analysis](#architecture-decisions-and-cost-analysis)
- [Infrastructure](#infrastructure)
- [Prerequisites](#prerequisites)
- [Deployment](#deployment)
  - [Local Development](#local-development)
  - [Production Deployment](#production-deployment)
- [Testing the Deployment](#testing-the-deployment)
- [API Endpoints Reference](#api-endpoints-reference)
- [Adding New Models](#adding-new-models)
- [Monitoring and Logging](#monitoring-and-logging)
- [Security](#security)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)

## Architecture

The platform follows a microservices architecture with the following components:

1. **API Gateway**: A Node.js application that acts as the single entry point for all client requests. It:
   - Routes requests to the appropriate model server
   - Handles load balancing between model instances
   - Provides a unified API interface
   - Manages authentication and rate limiting
   - Exposes HTTPS endpoints through AWS API Gateway
   - Securely proxies requests to internal model servers
   - Only component exposed to the internet
   - Implements rate limiting (100 requests per 60 seconds)
   - Includes security headers and CORS configuration

2. **Model Servers**: Individual FastAPI applications, each dedicated to serving a specific Hugging Face model. Each model server:
   - Runs in its own container
   - Has its own Kubernetes deployment and service
   - Loads and serves a specific model
   - Exposes a health endpoint at `/health`
   - Exposes model-specific endpoints at `/generate`
   - Can be scaled independently based on demand
   - Only accessible within the cluster (ClusterIP service type)

3. **AWS Load Balancer Controller**: Manages AWS Application Load Balancers (ALB) for the Kubernetes cluster:
   - Automatically provisions and configures ALBs
   - Handles ingress traffic routing
   - Manages target groups and health checks
   - Integrates with AWS WAF for security
   - Supports SSL/TLS termination
   - Provides automatic scaling based on traffic
   - Uses OIDC for secure AWS service integration

4. **Infrastructure Components**:
   - AWS EKS for container orchestration
   - AWS ECR for container registry
   - AWS VPC for networking
   - AWS API Gateway for HTTPS endpoints
   - AWS Load Balancer for traffic distribution
   - AWS WAF for web application firewall
   - AWS CloudWatch for monitoring
   - Terraform for infrastructure as code
   - GitHub Actions for CI/CD

The infrastructure is organized into the following Terraform modules:
- `api_gateway`: Manages the AWS API Gateway configuration
- `vpc`: Sets up the VPC and networking components
- `eks`: Configures the EKS cluster
- `ecr`: Manages container repositories
- `iam`: Handles IAM roles and policies
- `monitoring`: Sets up CloudWatch monitoring
- `waf`: Manages AWS WAF Web ACL for API protection
- `cloudfront`: Configures CloudFront distribution for content delivery and caching

### Traffic Flow

1. User sends HTTPS request to CloudFront
2. CloudFront forwards request to WAF
3. WAF applies security rules and forwards to API Gateway
4. API Gateway routes request through VPC Link
5. AWS Load Balancer Controller manages ALB routing
6. ALB forwards to API Gateway pod
7. API Gateway pod processes request and forwards to model service
8. Model service processes request and returns response
9. Response flows back through the same path

For a more detailed architecture overview, including component interactions and security features, please refer to the [architecture documentation](./architecture/architecture.md) and [architecture diagram](./architecture/mermaid-diagram.mmd) in the `architecture` folder.

## Architecture Decisions and Cost Analysis

### CPU vs GPU Decision

The platform is designed to use CPU-only inference for the following reasons:

1. **Cost Efficiency**:
   - CPU (t3.large): ~$0.0832/hour per instance
   - GPU (g4dn.xlarge): ~$0.526/hour per instance
   - Cost difference: ~6.3x more expensive for GPU

2. **Resource Requirements**:
   - Current setup: 2 × t3.large nodes (4 vCPU, 16 GiB each)
   - Total cost: ~$0.1664/hour (~$120/month)
   - Sufficient for current workload and future model additions

3. **Performance Considerations**:
   - GPT-2 is a relatively small model (117M parameters)
   - CPU inference is adequate for most use cases
   - Latency is acceptable for non-real-time applications

4. **Scalability**:
   - Horizontal scaling with CPU nodes is more cost-effective
   - Can add more nodes as needed
   - Better resource utilization

### Infrastructure Costs (Monthly)

1. **Compute (EKS Nodes)**:
   - 2 × t3.large instances: ~$120/month
   - Auto-scaling enabled for cost optimization

2. **Container Registry (ECR)**:
   - ~$5-10/month for image storage
   - Based on number of models and image sizes

3. **Networking**:
   - ~$20-30/month for data transfer

4. **Security & CDN**:
   - AWS WAF: ~$5/month
   - CloudFront: ~$10-15/month (based on data transfer)
   - Regional WAF: ~$5/month

5. **Total Estimated Cost**:
   - ~$165-180/month for the entire platform
   - Cost-effective for development and testing
   - Can be optimized further based on usage patterns

### Future Scaling

The platform is designed to scale efficiently:

1. **Adding New Models**:
   - Each model server requires ~1 CPU, 2Gi memory
   - Current setup can handle 2-3 models comfortably
   - Auto-scaling will add nodes as needed

2. **Cost Optimization**:
   - Auto-scaling based on demand
   - Resource requests/limits for efficient allocation
   - Monitoring and alerting for cost control

3. **Performance Monitoring**:
   - CloudWatch metrics for resource usage
   - Cost tracking and optimization
   - Performance metrics for scaling decisions

### Security Architecture

The platform implements a secure architecture with the following features:

1. **Network Security**:
   - API Gateway exposed via LoadBalancer service type
   - Model servers restricted to ClusterIP service type
   - Internal communication through Kubernetes service discovery
   - All services run in private subnets
   - Network policies for pod-to-pod communication
   - CloudFront distribution for edge security
   - Regional WAF for API protection

2. **API Gateway Security**:
   - Helmet middleware for security headers
   - CORS configuration
   - Request validation
   - Rate limiting
   - Error handling and logging
   - AWS WAF integration with managed rules:
     - Rate limiting (100 requests per IP)
     - AWS Managed Rules Common Rule Set
     - SQL Injection Protection
     - Amazon IP Reputation List
   - CloudFront distribution for:
     - DDoS protection
     - SSL/TLS termination
     - Geographic restrictions
     - Request caching
     - Edge security

3. **Model Server Security**:
   - No direct internet access
   - Internal service discovery
   - Resource limits and requests
   - Health checks and probes

### Naming Conventions

The project follows strict naming conventions for all resources:

1. **Resource Names**:
   - Format: `${PROJECT_NAME}-${ENVIRONMENT}-${COMPONENT}`
   - Example: `huggingface-dev-api-gateway`

2. **Labels**:
   - `app: ${PROJECT_NAME}-${ENVIRONMENT}-${COMPONENT}`
   - `project: ${PROJECT_NAME}`
   - `environment: ${ENVIRONMENT}`
   - `component: ${COMPONENT}`
   - `model: ${MODEL_NAME}` (for model servers)

3. **Environment Variables**:
   - `PROJECT_NAME`: Project identifier (e.g., "huggingface")
   - `ENVIRONMENT`: Deployment environment (e.g., "local", "dev", "prod")
   - `MODEL_NAME`: Model identifier (e.g., "gpt2")
   - `COMPONENT`: Component type (e.g., "api-gateway", "model-server")

The system is designed to be easily extensible - new models can be added by:
1. Creating a new model server deployment
2. Adding the model's service URL to the API Gateway configuration
3. The API Gateway automatically discovers and routes to the new model

## Infrastructure

- k3d for local development
- AWS EKS for production container orchestration
- AWS ECR for container registry
- AWS VPC for networking
- AWS API Gateway for HTTPS endpoints and security
- Terraform for infrastructure as code
- GitHub Actions for CI/CD

The infrastructure is organized into the following Terraform modules:
- `api_gateway`: Manages the AWS API Gateway configuration
- `vpc`: Sets up the VPC and networking components
- `eks`: Configures the EKS cluster
- `ecr`: Manages container repositories
- `iam`: Handles IAM roles and policies
- `monitoring`: Sets up CloudWatch monitoring
- `alb_controller`: Configures AWS Load Balancer Controller
- `waf`: Manages AWS WAF Web ACL for API protection
- `cloudfront`: Configures CloudFront distribution for content delivery and caching

## Prerequisites

- Docker installed
- k3d installed (for local development)
- kubectl installed
- Node.js and npm installed
- Python 3.9+ installed
- AWS CLI configured (for production deployment)
- Terraform installed (for production deployment)
- act installed (for local GitHub Actions testing)
- jq installed (for AWS credentials handling)

## Deployment

### Local Development

1. Clone the repository:
```bash
git clone https://github.com/your-org/huggingface.git
cd huggingface
```

2. Run the local development script:
```bash
./scripts/kubernetes-local.bash
```

This script will:
- Build Docker images for the API Gateway and Model Server
- Create a local k3d cluster
- Deploy the services
- Run tests to verify the setup

3. Test GitHub Actions locally:
```bash
# Run the test script which handles prerequisites and workflow testing
./scripts/test-workflow.bash
```

The script will:
- Check and install required prerequisites
- Verify AWS SSO login
- Load necessary secrets
- Test the workflow for the dev environment
- Provide colored output for status updates

### Production Deployment

The deployment process must be followed in the correct order due to dependencies between components, particularly the AWS Load Balancer Controller. Follow these steps in sequence:

1. Deploy the core infrastructure using Terraform:
```bash
./scripts/deploy-terraform.bash
```
This script will:
- Deploy core infrastructure (VPC, Security Groups, EKS)
- Create ECR repositories
- Apply security group rules
- Wait for the EKS cluster to be ready

2. Build and push Docker images to ECR:
```bash
./scripts/deploy-ecr-docker.bash
```
This script will:
- Build Docker images for the API Gateway and Model Server
- Push images to ECR repositories

3. Deploy Kubernetes resources and AWS Load Balancer Controller:
```bash
./scripts/deploy-kubernetes.bash
```
This script will:
- Set up OIDC provider for the cluster
- Install AWS Load Balancer Controller using Helm
- Deploy the API Gateway and Model Server
- Configure ALB ingress and target groups
- Wait for deployments to be ready
- Display the API Gateway endpoint
- Test the deployment with sample requests

### Testing the Deployment

After deployment, you can test the setup using the following endpoints:

1. API Gateway Health Check:
```bash
curl -v https://<API_GATEWAY_ENDPOINT>/health
```
Response: `{ "status": "healthy" }`

2. Model Status Check:
```bash
curl -v https://<API_GATEWAY_ENDPOINT>/models/<MODEL_NAME>/status
```
Response: Model health status from the specific model server

3. Text Generation:
```bash
curl -v -X POST https://<API_GATEWAY_ENDPOINT>/models/<MODEL_NAME>/generate \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Hello, how are you?",
    "max_length": 50
  }'
```
Response: Generated text from the model

The API Gateway includes several security features:
- HTTPS encryption
- Rate limiting (100 requests per 60 seconds)
- Security headers (CORS, CSP, etc.)
- Request validation
- Error handling and logging

You can monitor the rate limits through the response headers:
- `ratelimit-limit`: Maximum requests allowed
- `ratelimit-remaining`: Remaining requests in the current window
- `ratelimit-reset`: Time until the rate limit resets

### API Endpoints Reference

| Endpoint | Method | Description | Timeout |
|----------|--------|-------------|---------|
| `/health` | GET | Check API Gateway health | 5s |
| `/models/:modelName/status` | GET | Check specific model health | 5s |
| `/models/:modelName/generate` | POST | Generate text using the model | 30s |

#### Request Validation

The API includes built-in validation for:
- Model name format
- Generate request payload structure
- Required fields
- Data types

#### Error Handling

The API provides detailed error responses:
- 400: Validation errors
- 500: Internal server errors
- Model-specific errors are propagated from the model servers

## Monitoring and Logging

- CloudWatch for logs and metrics
- AWS Load Balancer metrics
- EKS cluster metrics
- Container logs
- Application logs
- Security monitoring

## Security

- All services run in private subnets
- API Gateway exposed through LoadBalancer
- Model servers restricted to ClusterIP
- IAM roles for service accounts
- Network policies for pod communication
- GitHub Actions OIDC integration for secure AWS access
- AWS WAF for API protection
- CloudWatch alarms for security monitoring

## Scaling

The platform automatically scales based on:
- CPU and memory usage
- Number of requests
- Model loading time

## Adding New Models

### 1. Create Model Directory

Create a new directory for your model in `huggingface-models/models/`:
```bash
mkdir -p huggingface-models/models/your-model-name
```

### 2. Create Model Server

Create a FastAPI application for your model that:
- Loads the model on startup
- Exposes a `/health` endpoint
- Exposes a `/models/{model_name}/generate` endpoint
- Implements proper error handling
- Includes logging
- Follows the project's coding standards

### 3. Create Kubernetes Deployment

Create a new deployment file in `k8s/model-deployments/your-model-deployment.yaml` that includes:
- Deployment configuration
- Service configuration
- Resource requests and limits
- Health checks
- Environment variables
- Security context

Note: You must also create or update a NetworkPolicy in `k8s/model-deployments/` to:
- Allow traffic from the API Gateway to your model server
- Restrict traffic to only necessary ports
- Define ingress and egress rules
- Specify allowed namespaces and pods

### 4. Add ECR Repository

Add a new repository for your model in the ECR module (`terraform/modules/ecr/main.tf`):
```hcl
resource "aws_ecr_repository" "your_model" {
  name                 = "${var.project_name}-your-model-model-server"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-your-model-model-server"
    }
  )
}

resource "aws_ecr_lifecycle_policy" "your_model" {
  repository = aws_ecr_repository.your_model.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 30 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 30
      }
      action = {
        type = "expire"
      }
    }]
  })
}
```

### 5. Update API Gateway Configuration

Add your model's service URL to `gateway/src/services/modelServices.ts`:
```typescript
const modelServices: ModelServices = {
  gpt2: process.env.GPT2_SERVICE_URL || 'http://model-server:8000',
  yourModel: process.env.YOUR_MODEL_SERVICE_URL || 'http://your-model-server:8000',
  // Add more models as needed
};
```

### 6. Deploy the New Model

1. Build the model image:
```bash
docker build --no-cache -t huggingface-your-model-model-server:stable \
  -f ./huggingface-models/models/your-model/Dockerfile.your-model \
  ./huggingface-models
```

2. Push the model image to ECR:
```bash
# Get ECR login token
aws ecr get-login-password --region <AWS_REGION> | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com

# Tag the image
docker tag huggingface-your-model-model-server:stable <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/${PROJECT_NAME}-your-model-model-server:stable

# Push to ECR
docker push <AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/${PROJECT_NAME}-your-model-model-server:stable
```

3. Deploy to Kubernetes:
```bash
kubectl apply -f k8s/model-deployments/your-model-deployment.yaml
kubectl apply -f k8s/model-deployments/your-model-network-policy.yaml
```

4. Test the new model:
```bash
curl -X POST http://<API_GATEWAY_ENDPOINT>:3000/models/your-model/generate \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, how are you?", "max_length": 50}'
```

## Troubleshooting

1. Check pod status:
```bash
kubectl get pods -n ${NAMESPACE}
```

2. View logs:
```bash
kubectl logs -f deployment/${PROJECT_NAME}-${ENVIRONMENT}-api-gateway -n ${NAMESPACE}
kubectl logs -f deployment/${PROJECT_NAME}-${ENVIRONMENT}-gpt2-model-server -n ${NAMESPACE}
```

3. Check service status:
```bash
kubectl get services -n ${NAMESPACE}
```

4. Check Terraform state:
```bash
cd terraform/environments/dev  # or prod
terraform state list
terraform show
``` 