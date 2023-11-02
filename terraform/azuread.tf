data "azuread_service_principal" "this" {
  display_name = azurerm_linux_function_app.this.name
}

resource "azuread_directory_role_assignment" "this" {
  role_id             = "88d8e3e3-8f55-4a1e-953a-9b9898b8876b" # Directory Readers
  principal_object_id = data.azuread_service_principal.this.object_id
}
