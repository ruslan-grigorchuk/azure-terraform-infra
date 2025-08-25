# Azure Terraform Infrastructure

A comprehensive, enterprise-grade Terraform project for provisioning Azure infrastructure with DevOps best practices. This project demonstrates proper enterprise patterns, security, and maintainability.

[![Terraform](https://img.shields.io/badge/Terraform-≥1.5.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure)](https://azure.microsoft.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Architecture Overview

This infrastructure project provisions a complete Azure environment suitable for modern web applications:

```
┌─────────────────────────────────────────────────────────────────┐
│                          Azure Subscription                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌──────────────────┐   ┌─────────────┐  │
│  │   App Service   │    │   SQL Database   │   │ Storage     │  │
│  │   - Web App     │    │   - Azure SQL    │   │ Account     │  │
│  │   - Custom      │    │   - Backups      │   │ - Blobs     │  │
│  │     Domain      │    │   - Security     │   │ - Queues    │  │
│  │   - SSL/TLS     │    │   - Monitoring   │   │ - Tables    │  │
│  └─────────────────┘    └──────────────────┘   └─────────────┘  │
│           │                       │                     │       │
│           │              ┌────────▼─────────────────────▼──┐    │
│           │              │          Key Vault              │    │
│           │              │    - Secrets Management         │    │
│           │              │    - Certificate Storage        │    │
│           │              │    - Connection Strings         │    │
│           │              └─────────────────────────────────┘    │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐    ┌──────────────────┐   ┌─────────────┐  │
│  │ Application     │    │   Service Bus    │   │    AKS      │  │
│  │ Insights        │    │   - Queues       │   │ - K8s       │  │
│  │ - Monitoring    │    │   - Topics       │   │ - Nodes     │  │
│  │ - Logging       │    │   - Subscriptions│   │ - Scaling   │  │
│  │ - Alerts        │    │   - Dead Letter  │   │             │  │
│  │ - Dashboards    │    │     Handling     │   │             │  │
│  └─────────────────┘    └──────────────────┘   └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Features

### Infrastructure Components
- **Azure App Service**: Scalable web application hosting with custom domain support
- **Azure SQL Database**: Managed database with automated backups and security features
- **Azure Storage Account**: Blob, queue, and table storage with lifecycle management
- **Azure Key Vault**: Centralized secrets and certificate management
- **Application Insights**: Comprehensive application monitoring and analytics
- **Azure Service Bus**: Reliable messaging between distributed components
- **Azure Kubernetes Service (AKS)**: Container orchestration platform (optional)

### Enterprise Features
- **Multi-Environment Support**: Separate configurations for dev, staging, and production
- **Security Best Practices**: RBAC, network security groups, private endpoints
- **Cost Optimization**: Resource tagging, auto-scaling, lifecycle policies
- **Monitoring & Alerting**: Built-in monitoring, logging, and alerting
- **Disaster Recovery**: Geo-redundant storage and backup strategies
- **Compliance**: Security scanning, audit logging, and compliance reporting

### DevOps Best Practices
- **Modular Design**: Reusable Terraform modules for each service
- **State Management**: Remote state with locking mechanisms
- **CI/CD Ready**: Automation scripts and validation tools
- **Documentation**: Comprehensive documentation and examples
- **Security Scanning**: Built-in security validation and checks

## Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.40.0
- [Git](https://git-scm.com/) for version control

### Optional Tools (Recommended)
- [TFLint](https://github.com/terraform-linters/tflint) - Terraform linting
- [TFSec](https://github.com/aquasecurity/tfsec) - Security scanning
- [terraform-docs](https://github.com/terraform-docs/terraform-docs) - Documentation generation

### Azure Requirements
- Azure Subscription with appropriate permissions
- Service Principal or User Account with Contributor access
- Resource quotas for planned resources

## 🛠️ Quick Start

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd azure-terraform-infra

# Copy example configuration
cp local.tfvars.example local.tfvars

# Edit configuration with your values
nano local.tfvars
```

### 2. Azure Authentication
```bash
# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "Your Subscription ID"

# Verify access
az account show
```

### 3. Initialize Terraform
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review planned changes
terraform plan -var-file="local.tfvars"
```

### 4. Deploy Infrastructure
```bash
# Apply configuration
terraform apply -var-file="local.tfvars"

# Or use the deployment script
./scripts/deploy.sh -e dev
```

## Project Structure

```
azure-terraform-infra/
├── 📁 environments/              # Environment-specific configurations
│   ├── 📁 dev/
│   │   └── terraform.tfvars     # Development environment variables
│   ├── 📁 staging/
│   │   └── terraform.tfvars     # Staging environment variables
│   └── 📁 prod/
│       └── terraform.tfvars     # Production environment variables
├── 📁 modules/                   # Reusable Terraform modules
│   ├── 📁 app_service/          # Azure App Service module
│   ├── 📁 sql_database/         # Azure SQL Database module
│   ├── 📁 storage_account/      # Azure Storage Account module
│   ├── 📁 key_vault/            # Azure Key Vault module
│   ├── 📁 application_insights/ # Application Insights module
│   ├── 📁 service_bus/          # Azure Service Bus module
│   └── 📁 aks/                  # Azure Kubernetes Service module
├── 📁 scripts/                   # Automation scripts
│   ├── deploy.sh                # Deployment automation
│   └── validate.sh              # Validation and security checks
├── 📁 docs/                      # Additional documentation
├── terraform.tf                 # Terraform configuration
├── providers.tf                 # Provider configurations
├── variables.tf                 # Input variables
├── locals.tf                    # Local values
├── outputs.tf                   # Output values
├── main.tf                      # Main infrastructure configuration
├── .gitignore                   # Git ignore rules
├── local.tfvars.example         # Example local configuration
└── README.md                    # This file
```

## Configuration

### Environment Variables

Each environment has its own `terraform.tfvars` file with environment-specific settings:

#### Required Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `environment` | Environment name | `"dev"` |
| `location` | Azure region | `"East US"` |
| `project_name` | Project identifier | `"myapp"` |
| `owner` | Resource owner | `"DevOps Team"` |

#### Optional Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `app_service_sku` | App Service plan SKU | `"B1"` |
| `sql_sku_name` | SQL Database SKU | `"S0"` |
| `storage_account_tier` | Storage performance tier | `"Standard"` |
| `enable_service_bus` | Enable Service Bus | `false` |

### Network Security

Configure IP restrictions and network access:

```hcl
# Allow specific IP ranges
allowed_ip_ranges = [
  "10.0.0.0/8",        # Internal network
  "203.0.113.0/24",    # Office network
  "YOUR.IP.HERE/32"    # Your IP address
]
```

### Resource Tagging

All resources are tagged with:
- Environment
- Project name
- Owner
- Cost center
- Creation date
- Managed by Terraform

## Security

### Key Vault Integration
All sensitive data is stored in Azure Key Vault:
- SQL connection strings
- Storage account keys
- Service Bus connection strings
- Application secrets

### Network Security
- Private endpoints for secure connectivity
- Network security groups with minimal required access
- IP restrictions on public endpoints
- TLS 1.2+ enforcement

### RBAC and Identity
- Managed identities for service-to-service authentication
- Azure AD integration for AKS
- Principle of least privilege access

## Monitoring

### Application Insights
- Application performance monitoring
- Custom dashboards and workbooks
- Availability tests
- Smart detection rules

### Diagnostic Logging
- Centralized logging to Log Analytics
- Audit logs for compliance
- Performance metrics and alerts

## Deployment

### Using Deployment Script
```bash
# Deploy to development
./scripts/deploy.sh -e dev

# Plan only (no changes)
./scripts/deploy.sh -e prod -p

# Destroy environment
./scripts/deploy.sh -e dev -d

# Auto-approve (use with caution)
./scripts/deploy.sh -e dev -a
```

### Manual Deployment
```bash
# Initialize and validate
terraform init
terraform validate

# Plan deployment
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply changes
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### CI/CD Integration
The project includes GitHub Actions workflows and Azure DevOps templates in the `docs/` directory.

## 🧪 Testing and Validation

### Pre-deployment Validation
```bash
# Run comprehensive validation
./scripts/validate.sh

# Format code
terraform fmt -recursive .

# Security scanning (if tools installed)
tfsec .
tflint .
```

### Post-deployment Testing
```bash
# Verify outputs
terraform output

# Test connectivity
curl -I $(terraform output -raw app_service_url)

# Check Application Insights
# Navigate to Azure portal and verify telemetry
```

## Troubleshooting

### Common Issues

#### Authentication Errors
```bash
# Re-authenticate with Azure
az login --tenant YOUR_TENANT_ID

# Verify permissions
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

#### State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Or use Azure CLI
az storage blob delete --account-name ACCOUNT --container-name CONTAINER --name terraform.tfstate.lock
```

#### Resource Naming Conflicts
- Storage account names must be globally unique
- Key Vault names must be globally unique
- Use the `random_integer` resource for unique suffixes

### Resource Limits
Check Azure subscription limits:
```bash
# Check compute quotas
az vm list-usage --location "East US"

# Check network limits
az network list-usages --location "East US"
```

## Cost Optimization

### Resource Sizing
- **Development**: Use Basic/Standard tiers
- **Staging**: Use Standard tiers with auto-scaling
- **Production**: Use Premium tiers with high availability

### Cost Controls
- Auto-scaling policies for App Service and AKS
- Storage lifecycle management
- Reserved instances for production workloads
- Cost alerts and budgets

### Cleanup Commands
```bash
# Destroy development environment
./scripts/deploy.sh -e dev -d

# Remove unused resources
az group delete --name myapp-dev-rg --yes --no-wait
```

## Additional Resources

### Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Training
- [Azure DevOps Learning Path](https://docs.microsoft.com/en-us/learn/paths/evolve-your-devops-practices/)
- [Terraform Associate Certification](https://www.hashicorp.com/certification/terraform-associate)

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Development Guidelines
- Follow Terraform naming conventions
- Update documentation for new features
- Run validation tests before submitting
- Include examples for new modules

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:
- Create an [issue](../../issues) for bugs and feature requests
- Check existing [documentation](docs/)
- Review [troubleshooting](#troubleshooting) section

---

**⚡ Built with enterprise DevOps best practices and 10+ years of cloud infrastructure expertise.**