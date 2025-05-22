# Hugging Face Project Architecture

This document explains the architecture of the Hugging Face project, which provides a secure and scalable way to serve Hugging Face models through an API Gateway.

## Architecture Overview

The architecture consists of several key components:

1. **CloudFront Distribution**
   - Global content delivery network
   - SSL/TLS termination
   - Geographic restrictions
   - Request caching
   - DDoS protection
   - Edge security

2. **AWS WAF**
   - Web Application Firewall
   - Rate limiting (100 requests per IP)
   - AWS Managed Rules Common Rule Set
   - SQL Injection Protection
   - Amazon IP Reputation List
   - Regional protection

3. **AWS API Gateway**
   - HTTP API with a stage for the environment (dev/prod)
   - Routes all requests to the internal load balancer
   - Uses VPC Link to securely connect to the VPC
   - Includes CORS configuration and security headers
   - Logs requests and metrics to CloudWatch

4. **VPC Infrastructure**
   - Private subnets for EKS cluster and ALB
   - Public subnets for NAT Gateway
   - Internet Gateway for outbound traffic
   - NAT Gateway for private subnet internet access

5. **EKS Cluster**
   - Runs in private subnets
   - Contains two main components:
     - API Gateway service
     - Model services (GPT-2 and others)
   - Uses Kubernetes services for internal communication
   - AWS Load Balancer Controller for ingress management

6. **AWS Load Balancer Controller**
   - Installed via Helm
   - Manages Application Load Balancers
   - Handles ingress traffic routing
   - Manages target groups and health checks
   - Integrates with AWS WAF
   - Supports SSL/TLS termination
   - Provides automatic scaling

7. **Security**
   - Security groups control traffic between components
   - API Gateway runs as non-root user
   - Containers have restricted capabilities
   - All internal traffic is HTTP
   - External traffic is HTTPS
   - OIDC-based authentication
   - Network policies for pod-to-pod communication

## Traffic Flow

1. User sends HTTPS request to CloudFront
2. CloudFront forwards request to WAF
3. WAF applies security rules and forwards to API Gateway
4. API Gateway routes request through VPC Link
5. AWS Load Balancer Controller manages ALB routing
6. ALB forwards to API Gateway pod
7. API Gateway pod processes request and forwards to model service
8. Model service processes request and returns response
9. Response flows back through the same path

## Monitoring

- CloudWatch logs for API Gateway requests
- CloudWatch alarms for 4xx and 5xx errors
- Health checks on API Gateway pods
- Metrics for request latency and errors
- AWS Load Balancer metrics
- WAF metrics and logs
- CloudFront metrics and logs

## Security Features

- HTTPS for external traffic
- VPC Link for secure internal communication
- Security groups for traffic control
- Non-root container execution
- Read-only root filesystem
- Dropped container capabilities
- Health checks and probes
- Rate limiting
- CORS configuration
- WAF protection
- CloudFront security features
- OIDC authentication
- Network policies 