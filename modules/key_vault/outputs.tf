output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_tenant_id" {
  description = "Tenant ID of the Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}

output "secret_ids" {
  description = "Map of secret names to their IDs"
  value       = { for name, secret in azurerm_key_vault_secret.secrets : name => secret.id }
}

output "secret_versions" {
  description = "Map of secret names to their versions"
  value       = { for name, secret in azurerm_key_vault_secret.secrets : name => secret.version }
}

output "certificate_ids" {
  description = "Map of certificate names to their IDs"
  value       = { for name, cert in azurerm_key_vault_certificate.certificates : name => cert.id }
}

output "certificate_thumbprints" {
  description = "Map of certificate names to their thumbprints"
  value       = { for name, cert in azurerm_key_vault_certificate.certificates : name => cert.thumbprint }
}