output "access_rule_ids" {
  description = "Map of \"<perimeter>|<profile>|<rule>\" to the access rule id."
  value       = { for k, r in azurerm_network_security_perimeter_access_rule.this : k => r.id }
}

output "association_ids" {
  description = "Map of \"<perimeter>|<profile>|<association>\" to the association id."
  value       = { for k, a in azurerm_network_security_perimeter_association.this : k => a.id }
}

output "ids" {
  description = "Map of perimeter name to its resource id (pass to the diagnostic-settings module to ship perimeter logs)."
  value       = { for k, p in azurerm_network_security_perimeter.this : k => p.id }
}

output "ids_zipmap" {
  description = "Map of perimeter name to a { name, id } object, for passing where both are needed together."
  value       = { for k, p in azurerm_network_security_perimeter.this : k => { name = p.name, id = p.id } }
}

output "names" {
  description = "The perimeter names."
  value       = keys(azurerm_network_security_perimeter.this)
}

output "profile_ids" {
  description = "Map of \"<perimeter>|<profile>\" to the profile id."
  value       = { for k, p in azurerm_network_security_perimeter_profile.this : k => p.id }
}

output "resource_group_name" {
  description = "Resource group name parsed from resource_group_id."
  value       = local.resource_group_name
}

output "subscription_id" {
  description = "Subscription id parsed from resource_group_id."
  value       = local.rg.subscription_id
}

output "tags" {
  description = "The tags applied to the perimeters."
  value       = var.tags
}
