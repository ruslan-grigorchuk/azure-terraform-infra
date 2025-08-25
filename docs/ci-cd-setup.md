# CI/CD Pipeline Setup Guide

This document provides comprehensive setup instructions for the Terraform infrastructure pipelines across Azure DevOps, GitLab CI/CD, and GitHub Actions.

## Overview

The project includes three enterprise-grade CI/CD pipeline configurations:

- **Azure DevOps** (`azure-pipelines.yml`) - Microsoft's native solution with advanced Azure integration
- **GitLab CI/CD** (`.gitlab-ci.yml`) - GitLab's comprehensive DevOps platform
- **GitHub Actions** (`.github/workflows/terraform.yml`) - GitHub's native automation platform

All pipelines follow the same enterprise patterns:
- Multi-environment deployment (dev → staging → prod)
- Security scanning with TFSec and Checkov
- Manual approval gates for production
- Comprehensive validation and testing
- Infrastructure drift detection
- Artifact management and reporting

## Prerequisites

### Azure Requirements
- Azure Subscription with appropriate permissions
- Service Principal with the following roles:
  - **Contributor** on target subscription
  - **Storage Blob Data Contributor** on Terraform state storage account
  - **User Access Administrator** (if deploying RBAC configurations)

### Terraform State Backend
Create an Azure Storage Account for remote state management:

```bash
# Create resource group for Terraform state
az group create --name terraform-state-rg --location "East US"

# Create storage account for Terraform state
az storage account create \
  --name tfstateXXXXX \
  --resource-group terraform-state-rg \
  --location "East US" \
  --sku Standard_LRS \
  --encryption-services blob

# Create container for state files
az storage container create \
  --name tfstate \
  --account-name tfstateXXXXX
```

## Azure DevOps Setup

### 1. Service Connection
Create an Azure Resource Manager service connection:
1. Go to Project Settings → Service connections
2. Create new service connection → Azure Resource Manager
3. Choose "Service principal (automatic)" or "Service principal (manual)"
4. Name it `azure-service-connection`

### 2. Variable Groups
Create a variable group named `terraform-secrets`:

| Variable | Value | Secure |
|----------|--------|--------|
| `serviceConnection` | azure-service-connection | No |
| `tfStateStorageAccount` | tfstateXXXXX | No |
| `tfStateContainer` | tfstate | No |
| `tfStateResourceGroup` | terraform-state-rg | No |

### 3. Environment Setup
Create environments with approval gates:
1. **development** - No approvals required
2. **staging** - Require approval from team lead
3. **production** - Require approval from senior team members + security review

### 4. Pipeline Setup
1. Create new pipeline from `azure-pipelines.yml`
2. Link the `terraform-secrets` variable group
3. Configure branch policies for main branch
4. Set up scheduled runs for drift detection

## GitLab CI/CD Setup

### 1. CI/CD Variables
Configure the following variables in Settings → CI/CD → Variables:

#### Azure Authentication (Protected + Masked)
| Variable | Description |
|----------|-------------|
| `AZURE_CLIENT_ID` | Service principal client ID |
| `AZURE_CLIENT_SECRET` | Service principal client secret |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |

#### Terraform State Backend (Protected)
| Variable | Description |
|----------|-------------|
| `TF_STATE_STORAGE_ACCOUNT` | Storage account name for state |
| `TF_STATE_CONTAINER` | Container name (e.g., gitlab-tfstate) |
| `TF_STATE_RESOURCE_GROUP` | Resource group for state storage |

#### Optional Environment URLs
| Variable | Description |
|----------|-------------|
| `APP_SERVICE_URL_DEV` | Development app URL |
| `APP_SERVICE_URL_STAGING` | Staging app URL |
| `APP_SERVICE_URL_PROD` | Production app URL |

### 2. Environment Protection
Configure environment protection rules:
1. **staging** - Manual deployment approval required
2. **production** - Manual approval + restrict to main branch only

### 3. Scheduled Pipelines
Set up scheduled pipeline for drift detection:
1. Go to CI/CD → Schedules
2. Create new schedule for weekly drift checks
3. Target: main branch
4. Cron: `0 2 * * 1` (Every Monday at 2 AM)

## GitHub Actions Setup

### 1. Repository Secrets
Add the following secrets in Settings → Secrets and variables → Actions:

#### Azure Authentication
| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Service principal client ID |
| `AZURE_CLIENT_SECRET` | Service principal client secret |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |

#### Terraform State Backend
| Secret | Description |
|--------|-------------|
| `TF_STATE_STORAGE_ACCOUNT` | Storage account name |
| `TF_STATE_CONTAINER` | Container name (e.g., github-tfstate) |
| `TF_STATE_RESOURCE_GROUP` | Resource group name |

### 2. Environment Protection
Configure deployment protection rules:
1. Go to Settings → Environments
2. Create environments: `development`, `staging`, `production`
3. For `staging` and `production`:
   - Add required reviewers
   - Set deployment branch restrictions to `main` only
   - Configure environment secrets if needed

### 3. Security Scanning
Enable GitHub Advanced Security features:
1. Go to Settings → Code security and analysis
2. Enable Dependency graph
3. Enable Dependabot security updates
4. Enable Code scanning (if available)

### 4. Scheduled Workflows
The drift detection workflow runs automatically on schedule. To modify:
```yaml
on:
  schedule:
    - cron: '0 2 * * 1'  # Every Monday at 2 AM UTC
```

## Security Best Practices

### Service Principal Setup
Create a dedicated service principal for each environment:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "terraform-cicd-prod" \
  --role contributor \
  --scopes /subscriptions/SUBSCRIPTION-ID

# Assign additional roles if needed
az role assignment create \
  --assignee APP-ID \
  --role "User Access Administrator" \
  --scope /subscriptions/SUBSCRIPTION-ID
```

### Secret Management
- Use separate service principals for different environments
- Rotate credentials regularly (90 days recommended)
- Use least privilege access principles
- Never commit secrets to repository
- Use environment-specific variable groups/secrets

### Pipeline Security
- Enable branch protection rules on main branch
- Require pull request reviews before merging
- Enable security scanning in all pipelines
- Use manual approval gates for production deployments
- Implement drift detection to catch unauthorized changes

## Pipeline Features

### Validation Stage
- Terraform format checking
- Configuration validation
- Custom validation scripts
- Security scanning with TFSec and Checkov
- Dependency vulnerability scanning

### Deployment Stages
- **Development**: Automatic deployment on develop/main branch
- **Staging**: Manual approval required (production-like testing)
- **Production**: Enhanced security validation + manual approval

### Security Scanning
- **TFSec**: Terraform security analysis
- **Checkov**: Infrastructure misconfiguration detection
- **Custom Validation**: Project-specific security rules
- **SARIF Integration**: Results uploaded to security dashboards

### Monitoring and Reporting
- Infrastructure drift detection
- Deployment artifact collection
- Health check validation
- Comprehensive logging and reporting

## Troubleshooting

### Common Issues

#### Authentication Failures
```bash
# Verify service principal permissions
az role assignment list --assignee SERVICE-PRINCIPAL-ID

# Test authentication
az login --service-principal \
  --username $AZURE_CLIENT_ID \
  --password $AZURE_CLIENT_SECRET \
  --tenant $AZURE_TENANT_ID
```

#### State Lock Issues
```bash
# List state locks
az storage blob list \
  --container-name tfstate \
  --account-name STORAGE-ACCOUNT

# Force unlock if needed (use with caution)
terraform force-unlock LOCK-ID
```

#### Pipeline Failures
1. Check service connection permissions
2. Verify variable group configuration
3. Review Terraform state backend settings
4. Check Azure subscription quotas
5. Validate environment protection rules

### Support Resources
- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

## Next Steps

1. Choose your preferred CI/CD platform
2. Follow the setup guide for your chosen platform
3. Configure service principals and secrets
4. Set up environment protection rules
5. Test the pipeline with a development deployment
6. Gradually promote through staging to production
7. Configure monitoring and drift detection
8. Establish operational procedures for maintenance