# Input bindings are passed in via param block.
param($Timer)

$ErrorActionPreference = "Stop"

# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
  Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
$currentUTCtime = (Get-Date).ToUniversalTime()
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

###################################################################################################
# Validate environment variables

if (-Not (Test-Path -Path ENV:API_FUNCTION_KEY)) {
  Write-Warning "API_FUNCTION_KEY environment variable is not set. Calling the backend API may fail."
}
if (-Not (Test-Path -Path ENV:WEBSITE_HOSTNAME)) {
  Write-Error "WEBSITE_HOSTNAME environment variable is not set."
  exit 1
}

$sendMailParams = @{}

if (-Not (Test-Path -Path ENV:MAIL_USERNAME)) {
  Write-Error "MAIL_USERNAME environment variable is not set."
  exit 1
} elseif (-Not (Test-EmailAddress $env:MAIL_USERNAME).IsValid) {
  Write-Error "MAIL_USERNAME environment variable is not a valid email address."
  exit 10
}

if (-Not (Test-Path -Path ENV:MAIL_PASSWORD)) {
  Write-Error "MAIL_PASSWORD environment variable is not set."
  exit 1
}

$sendMailParams.Credential = New-Object System.Management.Automation.PSCredential -ArgumentList $env:MAIL_USERNAME, (ConvertTo-SecureString -String $env:MAIL_PASSWORD -AsPlainText -Force)
$sendMailParams.From = $env:MAIL_USERNAME

# Clean the login envrioment variables.
$env:MAIL_USERNAME = $null
$env:MAIL_PASSWORD = $null
[System.GC]::Collect()

if (-Not (Test-Path -Path ENV:MAIL_RECIPIENT)) {
  Write-Error "MAIL_RECIPIENT environment variable is not set."
  exit 1
} elseif (-Not (Test-EmailAddress $env:MAIL_RECIPIENT).IsValid) {
  Write-Error "MAIL_RECIPIENT environment variable is not a valid email address."
  exit 11
} else {
  $sendMailParams.To = $env:MAIL_RECIPIENT
}

if (-Not (Test-Path -Path ENV:MAIL_SERVER)) {
  Write-Information "MAIL_SERVER environment variable is not set. Using default value `"smtp.gmail.com`"."
  $sendMailParams.Server = "smtp.gmail.com"
} else {
  $sendMailParams.Server = $env:MAIL_SERVER
}

if (-Not (Test-Path -Path ENV:MAIL_PORT)) {
  Write-Information "MAIL_PORT environment variable is not set. Using default value `"587`"."
  $sendMailParams.Port = 587
} else {
  $sendMailParams.Port = [int]$env:MAIL_PORT
}

if (-Not (Test-Path -Path ENV:MAIL_USE_SSL)) {
  Write-Information "MAIL_USE_SSL environment variable is not set. Using default value `"true`"."
  $sendMailParams.UseSsl = $true
} else {
  $sendMailParams.UseSsl = [bool]::Parse($env:MAIL_USE_SSL)
}

###################################################################################################
# Main

try {
  $apiEndpointUrl = "https://$($env:WEBSITE_HOSTNAME)/api/GetExpiredSecrets"
  $apiFunctionKey = $env:API_FUNCTION_KEY

  Write-Host "Calling API at $apiEndpointUrl with Function Key."
  $expiredSecrets = Invoke-RestMethod -Method Get `
    -Headers @{
    "x-functions-key" = $apiFunctionKey
  } `
    -Uri $apiEndpointUrl

  $expiredSecrets | Select-Object -Property ApplicationName, OwnerUsername -ExpandProperty ExpiredSecrets
} catch {
  Write-Error "Failed to get expired secrets from API."
  throw $_
}

$htmlTable = $expiredSecrets |
Select-Object -ExpandProperty ExpiredSecrets |
ConvertTo-Html -Fragment

$sendMailParams.Subject = "Expired Secrets Report"
$sendMailParams.HTML = @"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <body>
    <h1>Expired Secrets:</h1>
    $htmlTable
  </body>
</html>
"@

$mailResult = Send-EmailMessage @sendMailParams

if ($mailResult.Status -eq $true) {
  Write-Host "Successfully sent email from $($mailResult.SendFrom) to $($mailResult.SendTo) within $($mailResult.TimeToExecute).)"
} else {
  Write-Error "Failed to send email from $($mailResult.SendFrom) to $($mailResult.SendTo). Server response$($mailResult.Message)"
  throw $mailResult.Error
}
