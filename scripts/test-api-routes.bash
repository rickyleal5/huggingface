#!/bin/bash
set -e  # Exit on error

# Function to test an endpoint
test_endpoint() {
    local endpoint=$1
    local method=${2:-GET}
    local data=${3:-""}
    local max_retries=5
    local retry_count=0
    local success=false

    echo -e "\nTesting $endpoint..."
    
    while [ $retry_count -lt $max_retries ]; do
        if [ "$method" = "POST" ]; then
            if curl -s -X POST "${API_ENDPOINT}${endpoint}" \
                -H "Content-Type: application/json" \
                -d "$data" \
                --max-time 60; then
                success=true
                break
            fi
        else
            if curl -s --max-time 30 "${API_ENDPOINT}${endpoint}"; then
                success=true
                break
            fi
        fi
        
        echo "Request failed, retrying in 15 seconds... (attempt $((retry_count + 1))/$max_retries)"
        retry_count=$((retry_count + 1))
        sleep 15
    done

    if [ "$success" = true ]; then
        echo "✅ $endpoint test successful!"
        return 0
    else
        echo "❌ $endpoint test failed after $max_retries attempts"
        return 1
    fi
}

# Set environment (default to dev if not specified)
ENVIRONMENT=${1:-"dev"}

# Get API Gateway endpoint from Terraform output
echo "Getting API Gateway endpoint for $ENVIRONMENT environment..."
cd "$(dirname "$0")/../terraform/environments/${ENVIRONMENT}"
export API_ENDPOINT=$(terraform output -raw api_gateway_endpoint)
cd - > /dev/null

if [ -z "$API_ENDPOINT" ]; then
    echo "Error: Could not find API Gateway endpoint"
    exit 1
fi

echo "API Gateway endpoint: ${API_ENDPOINT}"
echo "Starting API route tests..."

# Test health endpoint
test_endpoint "/health"

# Test model status endpoint
test_endpoint "/models/gpt2/status"

# Test model generation endpoint
test_endpoint "/models/gpt2/generate" "POST" '{"text": "Hello, how are you?", "max_length": 50}'

echo -e "\nAll API Gateway routes tested!" 