# Overview

This is an azure function to retrieve expired app registration secrets from an API and send E-Mail notifications to the owners of the app registrations.

## Prerequisites

-   Azure Function App for Powershell Core
-   The Managed Identity of the Function App needs the `Directory Reader` role on the Azure AD tenant

### Getting Started

#### Terraform

1. Deploy the Azure infrastructure via `terraform apply`.

#### Functions

1. Deploy the functions to your function app via `func azure functionapp publish <FUNCTION_APP_NAME>`. The first executions will fail, because the app settings are not set yet.
2. App Setting `API_FUNCTION_KEY` with an Function Key to call `GetExpiredSecrets` function. You can create one via `openssl rand -hex 32`.
