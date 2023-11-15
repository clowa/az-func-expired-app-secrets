moved {
  from = azurerm_linux_function_app.this
  to   = azurerm_linux_function_app.main
}


resource "azurerm_linux_function_app" "main" {
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
    ftps_state = "Disabled"

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
      app_settings["MAIL_USERNAME"],
      app_settings["MAIL_PASSWORD"],
      app_settings["MAIL_RECIPIENT"],
      tags["hidden-link: /app-insights-resource-id"], # inconsistent formating of Azure API
    ]
  }
}


###############################################################################
# AzureAD Permissions

data "azuread_service_principal" "main" {
  display_name = azurerm_linux_function_app.main.name
}

resource "azuread_directory_role_assignment" "main" {
  role_id             = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b" # Directory Readers
  principal_object_id = data.azuread_service_principal.main.object_id
}
