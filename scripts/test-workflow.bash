#!/bin/bash

# Environment variables
AWS_PROFILE="<AWS_SSO_PROFILE>"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${YELLOW}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_error() {
    echo -e "${RED}[-] $1${NC}"
}

# Function to load secrets from .secrets file
load_secrets() {
    print_status "Loading secrets from .secrets file..."
    
    if [ ! -f .secrets ]; then
        print_error ".secrets file not found"
        exit 1
    fi
    
    # Source the secrets file
    source .secrets
    
    # Verify required secrets are present
    if [ -z "$AWS_REGION" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_ROLE_ARN" ]; then
        print_error "Required AWS secrets are missing from .secrets file"
        exit 1
    fi
    
    print_success "Secrets loaded successfully!"
}

# Check AWS SSO login
check_aws_sso() {
    print_status "Checking AWS SSO login..."
    
    # Check if AWS SSO is configured
    if ! aws configure list-profiles &> /dev/null; then
        print_error "AWS SSO is not configured. Please run 'aws configure sso' first."
        exit 1
    fi
    
    # Check if we have valid SSO credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_status "AWS SSO session expired or not logged in. Attempting to login..."
        if ! aws sso login --profile ${AWS_PROFILE}; then
            print_error "Failed to login to AWS SSO. Please login manually using 'aws sso login'."
            exit 1
        fi
    fi
    
    print_success "AWS SSO login verified!"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    # Check if act is installed
    if ! command -v act &> /dev/null; then
        print_status "act is not installed. Installing act..."
        curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash -s -- -b /usr/local/bin
    fi
    
    # Check if .actrc exists
    if [ ! -f .actrc ]; then
        print_error ".actrc file not found. Please create it first."
        exit 1
    fi
    
    # Check if required tools are installed
    for tool in terraform kubectl helm aws; do
        if ! command -v $tool &> /dev/null; then
            print_error "$tool is not installed. Please install it first."
            exit 1
        fi
    done
    
    # Load secrets
    load_secrets
    
    # Check AWS SSO login
    check_aws_sso
    
    print_success "All prerequisites are met!"
}

# Test the workflow
test_workflow() {
    local environment=$1
    print_status "Testing workflow for environment: $environment"
    
    # Prefer credentials from .secrets if present
    if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ] && [ -n "$AWS_SESSION_TOKEN" ]; then
        print_status "Using AWS credentials from .secrets file."
    else
        print_status "Extracting AWS credentials from SSO profile ${AWS_PROFILE}..."
        # Try to extract credentials from SSO session
        if ! command -v jq &> /dev/null; then
            print_status "jq not found, installing jq..."
            sudo apt-get update && sudo apt-get install -y jq
        fi
        creds=$(aws sts get-session-token --profile ${AWS_PROFILE} 2>/dev/null)
        export AWS_ACCESS_KEY_ID=$(echo $creds | jq -r .Credentials.AccessKeyId)
        export AWS_SECRET_ACCESS_KEY=$(echo $creds | jq -r .Credentials.SecretAccessKey)
        export AWS_SESSION_TOKEN=$(echo $creds | jq -r .Credentials.SessionToken)
        if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_SESSION_TOKEN" ]; then
            print_error "Failed to extract AWS credentials from SSO session."
            exit 1
        fi
    fi
    
    # Create event payload
    local event_payload=$(cat <<EOF
{
  "inputs": {
    "environment": "$environment"
  }
}
EOF
)
    
    # Run the workflow with the event payload and secrets file
    if act workflow_dispatch -e <(echo "$event_payload") --secret-file .secrets -v \
        --env AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
        --env AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
        --env AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN} \
        --env AWS_REGION=${AWS_REGION}; then
        print_success "Workflow completed successfully!"
    else
        print_error "Workflow failed!"
        return 1
    fi
}

# Main execution
main() {
    print_status "Starting workflow testing..."
    
    # Check prerequisites
    check_prerequisites
    
    # Test workflow for dev environment
    print_status "Testing workflow for dev environment..."
    if ! test_workflow "dev"; then
        print_error "Workflow testing failed for dev environment"
        exit 1
    fi
    
    print_success "All workflow tests completed successfully!"
}

# Run the script
main 