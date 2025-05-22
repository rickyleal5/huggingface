# GitHub Actions Setup Guide

This guide explains the steps required to set up GitHub Actions for automated deployment of the Hugging Face project.

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub repository with the project code
3. GitHub Actions enabled for the repository

## Required AWS Resources

### 1. Create IAM Roles for GitHub Actions

Create separate IAM roles for dev and prod environments that GitHub Actions can assume using OIDC. Here's the complete trust policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::<YOUR-AWS-ACCOUNT-ID>:oidc-provider/token.actions.githubusercontent.com"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub": "repo:<YOUR-GITHUB-ORG>/<YOUR-REPO>:ref:refs/heads/main"
                }
            }
        }
    ]
}
```

For the prod environment, create a similar role but with the condition:
```json
"token.actions.githubusercontent.com:sub": "repo:<YOUR-GITHUB-ORG>/<YOUR-REPO>:ref:refs/heads/prod"
```

### 2. Attach Required Policies to the IAM Roles

Attach the following policies to both IAM roles:

1. **AWS Managed Policies**:
   - `AmazonECR-FullAccess`
   - `AmazonEKSClusterPolicy`
   - `AmazonEKS_CNI_Policy`
   - `AmazonEKSWorkerNodePolicy`
   - `AmazonEKSVPCResourceController`
   - `AmazonEC2ContainerRegistryReadOnly`
   - `AmazonS3FullAccess`
   - `CloudFrontFullAccess`
   - `AWSWAFFullAccess`
   - `AmazonAPIGatewayAdministrator`
   - `CloudWatchFullAccess`

2. **Custom Policy for ECR and EKS Management**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetRepositoryPolicy",
                "ecr:DescribeRepositories",
                "ecr:ListImages",
                "ecr:DescribeImages",
                "ecr:BatchGetImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:PutImage",
                "ecr:CreateRepository",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:DeleteRepositoryPolicy",
                "ecr:SetRepositoryPolicy"
            ],
            "Resource": [
                "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/huggingface-api-gateway",
                "arn:aws:ecr:${AWS_REGION}:${AWS_ACCOUNT_ID}:repository/huggingface-gpt2-model-server"
            ]
        }
    ]
}
```

3. **Custom Policy for VPC and Network Management**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateVpc",
                "ec2:DeleteVpc",
                "ec2:DescribeVpcs",
                "ec2:CreateSubnet",
                "ec2:DeleteSubnet",
                "ec2:DescribeSubnets",
                "ec2:CreateInternetGateway",
                "ec2:DeleteInternetGateway",
                "ec2:AttachInternetGateway",
                "ec2:DetachInternetGateway",
                "ec2:CreateNatGateway",
                "ec2:DeleteNatGateway",
                "ec2:DescribeNatGateways",
                "ec2:CreateRouteTable",
                "ec2:DeleteRouteTable",
                "ec2:CreateRoute",
                "ec2:DeleteRoute",
                "ec2:AssociateRouteTable",
                "ec2:DisassociateRouteTable",
                "ec2:CreateSecurityGroup",
                "ec2:DeleteSecurityGroup",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:CreateVpcEndpoint",
                "ec2:DeleteVpcEndpoint",
                "ec2:DescribeVpcEndpoints"
            ],
            "Resource": [
                "arn:aws:ec2:${AWS_REGION}:${AWS_ACCOUNT_ID}:vpc/*",
                "arn:aws:ec2:${AWS_REGION}:${AWS_ACCOUNT_ID}:subnet/*",
                "arn:aws:ec2:${AWS_REGION}:${AWS_ACCOUNT_ID}:internet-gateway/*",
                "arn:aws:ec2:${AWS_REGION}:${AWS_ACCOUNT_ID}:natgateway/*",
                "arn:aws:ec2:${AWS_REGION}:${AWS_ACCOUNT_ID}:route-table/*",
                "arn:aws:ec2:${AWS_REGION}:${AWS_ACCOUNT_ID}:security-group/*",
                "arn:aws:ec2:${AWS_REGION}:${AWS_ACCOUNT_ID}:vpc-endpoint/*"
            ],
            "Condition": {
                "StringLike": {
                    "aws:ResourceTag/Project": "huggingface"
                }
            }
        }
    ]
}
```

4. **Custom Policy for Load Balancer Management**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:CreateTargetGroup",
                "elasticloadbalancing:DeleteTargetGroup",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:${AWS_REGION}:${AWS_ACCOUNT_ID}:loadbalancer/*",
                "arn:aws:elasticloadbalancing:${AWS_REGION}:${AWS_ACCOUNT_ID}:targetgroup/*",
                "arn:aws:elasticloadbalancing:${AWS_REGION}:${AWS_ACCOUNT_ID}:listener/*"
            ],
            "Condition": {
                "StringLike": {
                    "aws:ResourceTag/Project": "huggingface"
                }
            }
        }
    ]
}
```

5. **Custom Policy for IAM Role Management**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:DeleteRole",
                "iam:GetRole",
                "iam:PutRolePolicy",
                "iam:DeleteRolePolicy",
                "iam:AttachRolePolicy",
                "iam:DetachRolePolicy",
                "iam:PassRole",
                "iam:TagRole",
                "iam:UntagRole",
                "iam:ListRoleTags",
                "iam:ListAttachedRolePolicies",
                "iam:GetRolePolicy"
            ],
            "Resource": [
                "arn:aws:iam::${AWS_ACCOUNT_ID}:role/huggingface-*",
                "arn:aws:iam::${AWS_ACCOUNT_ID}:role/eks-*"
            ],
            "Condition": {
                "StringLike": {
                    "aws:ResourceTag/Project": "huggingface"
                }
            }
        }
    ]
}
```

6. **Custom Policy for S3 State Management**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetBucketLocation",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:GetBucketVersioning",
                "s3:PutBucketVersioning",
                "s3:GetBucketEncryption",
                "s3:PutBucketEncryption",
                "s3:GetBucketPolicy",
                "s3:PutBucketPolicy",
                "s3:DeleteBucketPolicy"
            ],
            "Resource": [
                "arn:aws:s3:::huggingface-terraform-state-${ENVIRONMENT}",
                "arn:aws:s3:::huggingface-terraform-state-${ENVIRONMENT}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "huggingface"
                }
            }
        }
    ]
}
```

7. **Custom Policy for DynamoDB State Lock**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DeleteTable",
                "dynamodb:DescribeTable",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:UpdateItem",
                "dynamodb:Query",
                "dynamodb:Scan"
            ],
            "Resource": [
                "arn:aws:dynamodb:${AWS_REGION}:${AWS_ACCOUNT_ID}:table/huggingface-terraform-state-${ENVIRONMENT}"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/Project": "huggingface"
                }
            }
        }
    ]
}
```

These policies now include:
1. Project-specific resource ARNs using variables (${AWS_REGION}, ${AWS_ACCOUNT_ID}, ${ENVIRONMENT})
2. Resource tagging conditions to ensure only project resources are affected
3. Specific ECR repository names
4. Scoped IAM role names
5. Environment-specific S3 and DynamoDB resources

Remember to:
1. Replace all variables (${AWS_REGION}, ${AWS_ACCOUNT_ID}, ${ENVIRONMENT}) with actual values
2. Ensure all resources are tagged with `Project: huggingface`
3. Adjust resource names if your naming convention differs
4. Consider adding additional conditions based on your security requirements

The cleanup workflow will use the same IAM role and policies, as it needs to be able to delete all the resources that were created during deployment.

## GitHub Repository Setup

### 1. Configure GitHub Environments

1. Go to your repository's Settings
2. Navigate to Environments
3. Create two environments: "dev" and "prod"
4. For each environment:
   - Add required reviewers (for prod)
   - Add wait timer (for prod)
   - Configure deployment protection rules

### 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings > Secrets and variables > Actions):

1. `AWS_ROLE_ARN`: The ARN of the IAM role for the dev environment
   - Format: `arn:aws:iam::<YOUR-AWS-ACCOUNT-ID>:role/<ROLE-NAME>`
2. `AWS_REGION`: Your AWS region (e.g., us-east-1)
3. `AWS_ACCOUNT_ID`: Your AWS account ID

For the prod environment, add:
1. `PROD_AWS_ROLE_ARN`: The ARN of the IAM role for the prod environment
   - Format: `arn:aws:iam::<YOUR-AWS-ACCOUNT-ID>:role/<ROLE-NAME>`

### 3. Configure GitHub Actions Permissions

1. Go to your repository's Settings
2. Navigate to Actions > General
3. Under "Workflow permissions":
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

### 4. Enable OIDC Provider in AWS

1. Go to the AWS IAM Console
2. Navigate to Identity providers
3. Click "Add provider"
4. Select "OpenID Connect"
5. Provider URL: `https://token.actions.githubusercontent.com`
6. Audience: `sts.amazonaws.com`
7. Click "Add provider"

## Terraform State Configuration

If you're using S3 for Terraform state:

1. Create separate S3 buckets for dev and prod Terraform state
2. Create separate DynamoDB tables for state locking
3. Update the Terraform backend configuration in `terraform/environments/dev/backend.tf` and `terraform/environments/prod/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "<YOUR-TERRAFORM-STATE-BUCKET>-dev"  # or -prod for prod
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "<YOUR-DYNAMODB-TABLE>-dev"  # or -prod for prod
    encrypt        = true
  }
}
```

## Deployment Process

The workflow will automatically:
1. Deploy to dev environment when changes are pushed to the main branch
2. Deploy to prod environment when changes are pushed to the prod branch

### Dev Environment
- Triggered by pushes to main branch
- Uses dev IAM role
- Deploys to dev EKS cluster
- Uses dev Terraform state

### Prod Environment
- Triggered by pushes to prod branch
- Uses prod IAM role
- Deploys to prod EKS cluster
- Uses prod Terraform state
- Requires approval (if configured)

## Verification Steps

After setting up everything:

1. Push a change to the main branch
2. Go to the Actions tab in your GitHub repository
3. Monitor the deployment workflow
4. Check the AWS Console to verify:
   - ECR repositories are created
   - EKS cluster is created
   - Load Balancer is created
   - API Gateway is deployed
   - Model server is deployed

## Troubleshooting

If the workflow fails:

1. Check the GitHub Actions logs for specific error messages
2. Verify all AWS permissions are correctly configured
3. Ensure the OIDC provider is properly set up
4. Check if the IAM role trust policy matches your repository
5. Verify all required secrets are set in GitHub
6. Check environment-specific configurations

## Security Considerations

1. The IAM roles should have the minimum required permissions
2. Use separate IAM roles for dev and prod environments
3. Regularly rotate access keys and credentials
4. Enable AWS CloudTrail to monitor AWS API calls
5. Use AWS Config to track configuration changes
6. Enable AWS GuardDuty for threat detection
7. Use separate ECR repositories for dev and prod
8. Implement proper network isolation between environments 