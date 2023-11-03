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

resource "azurerm_service_plan" "this" {
  name                = "${local.global_prefix}-asp"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tags                = local.tags #

  os_type = "Linux"

  sku_name = "Y1"
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
