terraform {
  # Start with this block commented out to bootstrap using a local terraform state
  # Uncomment after initial deployment, run "terraform init -migrate-state" to migrate the state to the new backend
  #
  # backend "azurerm" {
  #   tenant_id            = "4ed310c5-f7a0-49ec-982b-34aeeeaea662" # TEQWEK GmbH
  #   subscription_id      = "96c5b236-572d-4845-aa1c-2d1a1f12ab5d" # TEQWERK GmbH - MSDN - Cedric Ahlers
  #   storage_account_name = "teq0plgr0core0iac0stac"
  #   container_name       = "core"
  #   key                  = "azureFunctionPowershell/terraform.tfstate"
  #   use_azuread_auth     = true
  # }

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.43"
    }
  }
}

provider "azuread" {
  tenant_id = "452df130-4ad1-437a-8c0e-9be535aeb732" # Clowa
}

provider "azurerm" {
  features {}
  # tenant_id       = "4ed310c5-f7a0-49ec-982b-34aeeeaea662" # TEQWEK GmbH
  # subscription_id = "96c5b236-572d-4845-aa1c-2d1a1f12ab5d" # TEQWERK GmbH - MSDN - Cedric Ahlers
  tenant_id       = "452df130-4ad1-437a-8c0e-9be535aeb732" # Clowa
  subscription_id = "0a0a4299-b306-4dad-94de-862e8405fdbe" # teq-free-msdn-sandbox-sub
}

data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

locals {
  region = "West Europe"

  company     = "cwa"
  solution    = "func-ar-secrets"
  environment = "prod"

  global_prefix = "${local.company}-${local.solution}-${local.environment}"

  tags = {
    solution         = local.solution
    application      = local.solution
    deploymentMethod = "terraform"
  }
}
