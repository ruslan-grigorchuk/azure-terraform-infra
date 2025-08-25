#!/bin/bash

# Azure Terraform Infrastructure Deployment Script
# This script automates the deployment process with proper validation and error handling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=""
DESTROY=false
PLAN_ONLY=false
AUTO_APPROVE=false
BACKEND_CONFIG=""

# Functions
print_usage() {
    echo "Usage: $0 -e ENVIRONMENT [OPTIONS]"
    echo ""
    echo "Required:"
    echo "  -e, --environment   Environment to deploy (dev, staging, prod)"
    echo ""
    echo "Options:"
    echo "  -d, --destroy       Destroy infrastructure instead of creating"
    echo "  -p, --plan-only     Show plan only, don't apply changes"
    echo "  -a, --auto-approve  Auto approve changes (dangerous!)"
    echo "  -b, --backend       Backend configuration file path"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -e dev                    # Deploy to dev environment"
    echo "  $0 -e prod -p               # Show plan for prod environment"
    echo "  $0 -e staging -d             # Destroy staging environment"
    echo "  $0 -e dev -b backend-dev.tf  # Deploy with custom backend config"
}

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

validate_environment() {
    if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
        error "Invalid environment. Must be: dev, staging, or prod"
    fi
}

check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        error "Terraform is not installed or not in PATH"
    fi
    
    # Check if az CLI is installed
    if ! command -v az &> /dev/null; then
        error "Azure CLI is not installed or not in PATH"
    fi
    
    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        error "Not logged in to Azure. Run 'az login' first"
    fi
    
    # Check if environment tfvars file exists
    if [ ! -f "environments/${ENVIRONMENT}/terraform.tfvars" ]; then
        error "Environment configuration file not found: environments/${ENVIRONMENT}/terraform.tfvars"
    fi
    
    success "Prerequisites check passed"
}

init_terraform() {
    log "Initializing Terraform..."
    
    local init_args=()
    
    if [ -n "$BACKEND_CONFIG" ]; then
        init_args+=("-backend-config=$BACKEND_CONFIG")
    fi
    
    terraform init "${init_args[@]}"
    success "Terraform initialized"
}

validate_terraform() {
    log "Validating Terraform configuration..."
    terraform validate
    success "Terraform configuration is valid"
}

plan_terraform() {
    log "Creating Terraform plan..."
    
    local plan_args=(
        "-var-file=environments/${ENVIRONMENT}/terraform.tfvars"
        "-out=terraform-${ENVIRONMENT}.tfplan"
    )
    
    terraform plan "${plan_args[@]}"
    success "Terraform plan created"
}

apply_terraform() {
    log "Applying Terraform configuration..."
    
    local apply_args=("terraform-${ENVIRONMENT}.tfplan")
    
    if [ "$AUTO_APPROVE" = true ]; then
        warning "Auto-approve enabled - changes will be applied automatically"
    fi
    
    terraform apply "${apply_args[@]}"
    success "Terraform configuration applied successfully"
}

destroy_terraform() {
    log "Destroying Terraform infrastructure..."
    
    local destroy_args=(
        "-var-file=environments/${ENVIRONMENT}/terraform.tfvars"
    )
    
    if [ "$AUTO_APPROVE" = true ]; then
        destroy_args+=("-auto-approve")
        warning "Auto-approve enabled - infrastructure will be destroyed automatically"
    fi
    
    terraform destroy "${destroy_args[@]}"
    success "Infrastructure destroyed successfully"
}

show_outputs() {
    log "Showing Terraform outputs..."
    terraform output
}

cleanup() {
    log "Cleaning up temporary files..."
    rm -f terraform-*.tfplan
    success "Cleanup completed"
}

main() {
    log "Starting deployment script for environment: $ENVIRONMENT"
    
    # Change to script directory
    cd "$(dirname "$0")/.."
    
    check_prerequisites
    init_terraform
    validate_terraform
    
    if [ "$DESTROY" = true ]; then
        destroy_terraform
    else
        plan_terraform
        
        if [ "$PLAN_ONLY" = false ]; then
            apply_terraform
            show_outputs
        fi
    fi
    
    cleanup
    success "Deployment script completed successfully"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -d|--destroy)
            DESTROY=true
            shift
            ;;
        -p|--plan-only)
            PLAN_ONLY=true
            shift
            ;;
        -a|--auto-approve)
            AUTO_APPROVE=true
            shift
            ;;
        -b|--backend)
            BACKEND_CONFIG="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate required arguments
if [ -z "$ENVIRONMENT" ]; then
    error "Environment is required. Use -e or --environment flag."
fi

validate_environment

# Run main function
main