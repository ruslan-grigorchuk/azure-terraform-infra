#!/bin/bash

# Terraform Validation and Security Check Script
# Performs comprehensive validation of Terraform configuration

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((PASSED_CHECKS++))
}

failure() {
    echo -e "${RED}✗ $1${NC}"
    ((FAILED_CHECKS++))
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

run_check() {
    local check_name="$1"
    local check_command="$2"
    
    ((TOTAL_CHECKS++))
    log "Running: $check_name"
    
    if eval "$check_command" > /dev/null 2>&1; then
        success "$check_name"
        return 0
    else
        failure "$check_name"
        return 1
    fi
}

check_terraform_format() {
    log "Checking Terraform formatting..."
    if terraform fmt -check -recursive .; then
        success "Terraform formatting is correct"
    else
        failure "Terraform files need formatting. Run: terraform fmt -recursive ."
        return 1
    fi
}

check_terraform_validation() {
    log "Validating Terraform configuration..."
    
    # Initialize first
    terraform init -backend=false > /dev/null 2>&1
    
    if terraform validate; then
        success "Terraform validation passed"
    else
        failure "Terraform validation failed"
        return 1
    fi
}

check_tflint() {
    log "Running TFLint..."
    
    if command -v tflint &> /dev/null; then
        if tflint; then
            success "TFLint checks passed"
        else
            failure "TFLint found issues"
            return 1
        fi
    else
        warning "TFLint not installed - skipping linting checks"
    fi
}

check_tfsec() {
    log "Running TFSec security checks..."
    
    if command -v tfsec &> /dev/null; then
        if tfsec . --soft-fail; then
            success "TFSec security checks passed"
        else
            failure "TFSec found security issues"
            return 1
        fi
    else
        warning "TFSec not installed - skipping security checks"
    fi
}

check_file_structure() {
    log "Checking project structure..."
    
    local required_files=(
        "terraform.tf"
        "providers.tf" 
        "variables.tf"
        "outputs.tf"
        "main.tf"
        "locals.tf"
        ".gitignore"
        "README.md"
    )
    
    local required_dirs=(
        "modules"
        "environments"
        "environments/dev"
        "environments/staging"
        "environments/prod"
        "scripts"
    )
    
    local missing_files=()
    local missing_dirs=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ] && [ ${#missing_dirs[@]} -eq 0 ]; then
        success "Project structure is complete"
    else
        failure "Missing required files/directories:"
        for file in "${missing_files[@]}"; do
            echo "  - Missing file: $file"
        done
        for dir in "${missing_dirs[@]}"; do
            echo "  - Missing directory: $dir"
        done
        return 1
    fi
}

check_environment_configs() {
    log "Checking environment configurations..."
    
    local environments=("dev" "staging" "prod")
    local all_good=true
    
    for env in "${environments[@]}"; do
        local tfvars_file="environments/${env}/terraform.tfvars"
        
        if [ -f "$tfvars_file" ]; then
            # Check if required variables are present
            local required_vars=("environment" "location" "project_name" "owner")
            local missing_vars=()
            
            for var in "${required_vars[@]}"; do
                if ! grep -q "^$var\s*=" "$tfvars_file"; then
                    missing_vars+=("$var")
                fi
            done
            
            if [ ${#missing_vars[@]} -eq 0 ]; then
                success "Environment config valid: $env"
            else
                failure "Missing variables in $env: ${missing_vars[*]}"
                all_good=false
            fi
        else
            failure "Missing environment config: $tfvars_file"
            all_good=false
        fi
    done
    
    if [ "$all_good" = false ]; then
        return 1
    fi
}

check_module_structure() {
    log "Checking module structure..."
    
    local modules_dir="modules"
    local required_module_files=("main.tf" "variables.tf" "outputs.tf")
    local all_good=true
    
    if [ -d "$modules_dir" ]; then
        for module_dir in "$modules_dir"/*; do
            if [ -d "$module_dir" ]; then
                local module_name=$(basename "$module_dir")
                local missing_files=()
                
                for file in "${required_module_files[@]}"; do
                    if [ ! -f "$module_dir/$file" ]; then
                        missing_files+=("$file")
                    fi
                done
                
                if [ ${#missing_files[@]} -eq 0 ]; then
                    success "Module structure valid: $module_name"
                else
                    failure "Module $module_name missing: ${missing_files[*]}"
                    all_good=false
                fi
            fi
        done
    else
        failure "Modules directory not found"
        all_good=false
    fi
    
    if [ "$all_good" = false ]; then
        return 1
    fi
}

check_secrets_exposure() {
    log "Checking for exposed secrets..."
    
    local sensitive_patterns=(
        "password\s*=\s*\"[^\"]+\""
        "secret\s*=\s*\"[^\"]+\""
        "key\s*=\s*\"[^\"]+\""
        "token\s*=\s*\"[^\"]+\""
        "client_secret\s*=\s*\"[^\"]+\""
    )
    
    local found_secrets=false
    
    for pattern in "${sensitive_patterns[@]}"; do
        if grep -r -i -E "$pattern" . --include="*.tf" --include="*.tfvars" --exclude-dir=".terraform"; then
            found_secrets=true
        fi
    done
    
    if [ "$found_secrets" = false ]; then
        success "No exposed secrets found"
    else
        failure "Potential secrets found in configuration files"
        warning "Review the above findings and move secrets to Key Vault or environment variables"
        return 1
    fi
}

print_summary() {
    echo
    echo "=================================="
    echo "         VALIDATION SUMMARY"
    echo "=================================="
    echo "Total Checks: $TOTAL_CHECKS"
    echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
    echo "=================================="
    
    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}✅ All validation checks passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some validation checks failed!${NC}"
        return 1
    fi
}

main() {
    log "Starting Terraform validation..."
    
    # Change to project root
    cd "$(dirname "$0")/.."
    
    # Run all checks
    check_file_structure
    check_terraform_format
    check_terraform_validation
    check_environment_configs
    check_module_structure
    check_secrets_exposure
    check_tflint
    check_tfsec
    
    # Print summary
    print_summary
}

main