#!/bin/bash

################################################################################
# ECS Fargate Infrastructure Deployment Script
################################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
STACK_NAME=""
REGION="us-east-1"
TEMPLATE_FILE="ecs-fargate-infrastructure.yaml"
PARAMETERS_FILE=""

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy ECS Fargate infrastructure using CloudFormation

OPTIONS:
    -s, --stack-name NAME       Name of the CloudFormation stack (required)
    -r, --region REGION         AWS region (default: us-east-1)
    -p, --parameters FILE       Parameters file (JSON format)
    -t, --template FILE         Template file (default: ecs-fargate-infrastructure.yaml)
    -v, --validate-only         Only validate the template without deploying
    -h, --help                  Display this help message

EXAMPLES:
    # Validate template
    $0 --validate-only

    # Deploy with inline parameters
    $0 --stack-name my-app-prod --region us-east-1

    # Deploy with parameters file
    $0 --stack-name my-app-prod --parameters parameters-example.json

EOF
    exit 1
}

# Function to validate template
validate_template() {
    print_message "$YELLOW" "Validating CloudFormation template..."
    
    aws cloudformation validate-template \
        --template-body "file://${TEMPLATE_FILE}" \
        --region "${REGION}" > /dev/null
    
    print_message "$GREEN" "✓ Template validation successful"
}

# Function to create or update stack
deploy_stack() {
    print_message "$YELLOW" "Checking if stack exists..."
    
    if aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --region "${REGION}" > /dev/null 2>&1; then
        
        print_message "$YELLOW" "Stack exists. Updating..."
        local action="update-stack"
    else
        print_message "$YELLOW" "Stack does not exist. Creating..."
        local action="create-stack"
    fi
    
    # Build the AWS CLI command
    local cmd="aws cloudformation ${action} \
        --stack-name ${STACK_NAME} \
        --template-body file://${TEMPLATE_FILE} \
        --capabilities CAPABILITY_NAMED_IAM \
        --region ${REGION}"
    
    # Add parameters file if specified
    if [ -n "${PARAMETERS_FILE}" ]; then
        cmd="${cmd} --parameters file://${PARAMETERS_FILE}"
    fi
    
    # Execute the command
    print_message "$YELLOW" "Executing: ${cmd}"
    eval "${cmd}"
    
    print_message "$YELLOW" "Waiting for stack ${action} to complete..."
    
    if [ "${action}" == "create-stack" ]; then
        aws cloudformation wait stack-create-complete \
            --stack-name "${STACK_NAME}" \
            --region "${REGION}"
    else
        aws cloudformation wait stack-update-complete \
            --stack-name "${STACK_NAME}" \
            --region "${REGION}" 2>/dev/null || true
    fi
    
    print_message "$GREEN" "✓ Stack ${action} completed successfully"
}

# Function to display stack outputs
display_outputs() {
    print_message "$YELLOW" "Stack Outputs:"
    
    aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --region "${REGION}" \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table
    
    # Get the HTTPS endpoint specifically
    local https_endpoint=$(aws cloudformation describe-stacks \
        --stack-name "${STACK_NAME}" \
        --region "${REGION}" \
        --query 'Stacks[0].Outputs[?OutputKey==`HTTPSEndpoint`].OutputValue' \
        --output text)
    
    if [ -n "${https_endpoint}" ]; then
        print_message "$GREEN" "\n✓ Application URL: ${https_endpoint}"
    fi
}

# Parse command line arguments
VALIDATE_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -p|--parameters)
            PARAMETERS_FILE="$2"
            shift 2
            ;;
        -t|--template)
            TEMPLATE_FILE="$2"
            shift 2
            ;;
        -v|--validate-only)
            VALIDATE_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_message "$RED" "Unknown option: $1"
            usage
            ;;
    esac
done

# Main execution
print_message "$GREEN" "=================================="
print_message "$GREEN" "ECS Fargate Infrastructure Deployment"
print_message "$GREEN" "=================================="

# Check if template file exists
if [ ! -f "${TEMPLATE_FILE}" ]; then
    print_message "$RED" "Error: Template file '${TEMPLATE_FILE}' not found"
    exit 1
fi

# Validate template
validate_template

# If validate-only flag is set, exit here
if [ "$VALIDATE_ONLY" = true ]; then
    print_message "$GREEN" "Validation complete. Exiting."
    exit 0
fi

# Check if stack name is provided
if [ -z "${STACK_NAME}" ]; then
    print_message "$RED" "Error: Stack name is required for deployment"
    usage
fi

# Check if parameters file exists (if specified)
if [ -n "${PARAMETERS_FILE}" ] && [ ! -f "${PARAMETERS_FILE}" ]; then
    print_message "$RED" "Error: Parameters file '${PARAMETERS_FILE}' not found"
    exit 1
fi

# Deploy the stack
deploy_stack

# Display outputs
display_outputs

print_message "$GREEN" "\n=================================="
print_message "$GREEN" "Deployment Complete!"
print_message "$GREEN" "=================================="
