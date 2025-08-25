locals {
  # Common naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags applied to all resources
  common_tags = merge(
    {
      Environment     = var.environment
      Project         = var.project_name
      Owner           = var.owner
      ManagedBy       = "Terraform"
      CreatedDate     = formatdate("YYYY-MM-DD", timestamp())
      CostCenter      = var.cost_center
    },
    var.additional_tags
  )

  # Resource group name
  resource_group_name = "${local.name_prefix}-rg"

  # Generate random suffix for globally unique resources
  random_suffix = random_integer.suffix.result
}