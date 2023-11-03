resource "azurerm_resource_group" "this" {
  name     = "${local.global_prefix}-rg"
  location = local.region
  tags     = local.tags
}

resource "azurerm_storage_account" "this" {
  name                = replace("${local.global_prefix}-stac", "-", "")
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  account_tier                    = "Standard"
  account_kind                    = "Storage"
  account_replication_type        = "LRS"
  default_to_oauth_authentication = true

  blob_properties {
    change_feed_enabled      = false
    last_access_time_enabled = false
    versioning_enabled       = false
  }

  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Allow"
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${local.global_prefix}-log"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  sku = "PerGB2018"
}

resource "azurerm_application_insights" "this" {
  name                = "${local.global_prefix}-appi"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags

  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id
  sampling_percentage = 0
}


resource "azurerm_service_plan" "this" {
  name                = "${local.global_prefix}-asp"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags #

  os_type = "Linux"

  sku_name = "Y1"
}

resource "azurerm_linux_function_app" "this" {
  name                = "${local.global_prefix}-func"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags = merge(local.tags, {
    "hidden-link: /app-insights-conn-string"         = azurerm_application_insights.this.connection_string
    "hidden-link: /app-insights-instrumentation-key" = azurerm_application_insights.this.instrumentation_key
    "hidden-link: /app-insights-resource-id"         = azurerm_application_insights.this.id
  })

  service_plan_id            = azurerm_service_plan.this.id
  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  https_only                 = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on       = false
    app_scale_limit = 200
    ftps_state      = "FtpsOnly"

    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key

    application_stack {
      powershell_core_version = "7.2"
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
      app_settings["API_FUNCTION_KEY"],
      tags["hidden-link: /app-insights-resource-id"], # inconsistent formating of Azure API
    ]
  }
}

resource "azurerm_linux_function_app_slot" "preview" {
  name            = "preview"
  function_app_id = azurerm_linux_function_app.this.id
  tags = merge(local.tags, {
    "hidden-link: /app-insights-conn-string"         = azurerm_application_insights.this.connection_string
    "hidden-link: /app-insights-instrumentation-key" = azurerm_application_insights.this.instrumentation_key
    "hidden-link: /app-insights-resource-id"         = azurerm_application_insights.this.id
  })

  storage_account_name       = azurerm_storage_account.this.name
  storage_account_access_key = azurerm_storage_account.this.primary_access_key
  https_only                 = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    ftps_state = "Disabled"

    application_insights_connection_string = azurerm_application_insights.this.connection_string
    application_insights_key               = azurerm_application_insights.this.instrumentation_key

    application_stack {
      powershell_core_version = "7.2"
    }
  }
}
