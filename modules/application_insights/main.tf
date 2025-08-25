resource "azurerm_log_analytics_workspace" "main" {
  count               = var.workspace_id == "" ? 1 : 0
  name                = "${var.name}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days

  daily_quota_gb = var.daily_data_cap_in_gb

  tags = var.tags
}

data "azurerm_log_analytics_workspace" "existing" {
  count               = var.workspace_id != "" ? 1 : 0
  name                = split("/", var.workspace_id)[8]
  resource_group_name = split("/", var.workspace_id)[4]
}

locals {
  workspace_id = var.workspace_id != "" ? var.workspace_id : azurerm_log_analytics_workspace.main[0].id
}

resource "azurerm_application_insights" "main" {
  name                                  = var.name
  location                              = var.location
  resource_group_name                   = var.resource_group_name
  workspace_id                          = local.workspace_id
  application_type                      = var.application_type
  retention_in_days                     = var.retention_in_days
  sampling_percentage                   = var.sampling_percentage
  disable_ip_masking                    = var.disable_ip_masking
  internet_ingestion_enabled            = var.internet_ingestion_enabled
  internet_query_enabled                = var.internet_query_enabled
  force_customer_storage_for_profiler   = var.force_customer_storage_for_profiler
  local_authentication_disabled         = var.local_authentication_disabled
  daily_data_cap_in_gb                  = var.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled

  tags = var.tags
}

# Availability Tests (Web Tests)
resource "azurerm_application_insights_web_test" "tests" {
  for_each = { for test in var.availability_tests : test.name => test }

  name                    = each.value.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = azurerm_application_insights.main.id
  kind                    = "ping"
  frequency               = each.value.frequency
  timeout                 = each.value.timeout
  enabled                 = each.value.enabled
  retry_enabled           = each.value.retry_enabled
  geo_locations           = each.value.geo_locations
  description             = each.value.description

  configuration = templatefile("${path.module}/templates/webtest.xml", {
    name                 = each.value.name
    url                  = each.value.url
    expected_status_code = each.value.expected_status_code
    ssl_check_enabled    = each.value.ssl_check_enabled
    follow_redirects     = each.value.follow_redirects
  })

  tags = var.tags
}

# Metric Alerts for Availability Tests
resource "azurerm_monitor_metric_alert" "availability_alert" {
  for_each = { for test in var.availability_tests : test.name => test }

  name                = "${each.value.name}-availability-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_insights_web_test.tests[each.key].id]
  description         = "Alert when ${each.value.name} availability test fails"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Insights/webtests"
    metric_name      = "availabilityResults/availabilityPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 90

    dimension {
      name     = "availabilityResult/name"
      operator = "Include"
      values   = [each.value.name]
    }
  }

  dynamic "action" {
    for_each = var.action_groups
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Smart Detection Rules
resource "azurerm_application_insights_smart_detection_rule" "rules" {
  for_each = { for rule in var.smart_detection_rules : rule.name => rule }

  name                    = each.value.name
  application_insights_id = azurerm_application_insights.main.id
  enabled                 = each.value.enabled
  send_emails_to_subscription_owners = each.value.send_emails_to_subscription_owners
  additional_email_recipients = each.value.additional_email_recipients
}

# Workbook for Application Insights
resource "azurerm_application_insights_workbook" "main" {
  name                = "${var.name}-workbook"
  resource_group_name = var.resource_group_name
  location            = var.location
  display_name        = "${var.name} Application Dashboard"
  data_json = jsonencode({
    version = "Notebook/1.0"
    items = [
      {
        type = 1
        content = {
          json = "## Application Overview Dashboard\nThis workbook provides an overview of your application's performance and health metrics."
        }
      },
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query = "requests | summarize count() by bin(timestamp, 1h) | render timechart"
          size = 0
          title = "Request Count Over Time"
          timeContext = {
            durationMs = 86400000
          }
          queryType = 0
          resourceType = "microsoft.insights/components"
        }
      },
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query = "requests | summarize avg(duration) by bin(timestamp, 1h) | render timechart"
          size = 0
          title = "Average Response Time"
          timeContext = {
            durationMs = 86400000
          }
          queryType = 0
          resourceType = "microsoft.insights/components"
        }
      },
      {
        type = 3
        content = {
          version = "KqlItem/1.0"
          query = "exceptions | summarize count() by type | render piechart"
          size = 0
          title = "Exception Types"
          timeContext = {
            durationMs = 86400000
          }
          queryType = 0
          resourceType = "microsoft.insights/components"
        }
      }
    ]
    styleSettings = {}
  })

  tags = var.tags
}

# Performance Test Configuration (example)
resource "azurerm_application_insights_api_key" "read_only" {
  name                    = "${var.name}-readonly-key"
  application_insights_id = azurerm_application_insights.main.id
  read_permissions        = ["aggregate", "api", "draft", "extendqueries", "search"]
}