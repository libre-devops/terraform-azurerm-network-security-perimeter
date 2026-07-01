# Network Security Perimeters (keyed by name) with their profiles, access rules, and resource
# associations. A perimeter isolates PaaS resources behind a network boundary; profiles group the
# access rules, and associations bring a PaaS resource (Key Vault, storage, etc.) inside the perimeter.
# Associations default to Learning mode (observe, do not block) so onboarding is non-breaking; move to
# Enforced once the access rules are validated. Perimeter logs are shipped via the diagnostic-settings
# module (pass a perimeter id from the ids output), not from here. Resource group passed by id + parsed.

resource "azurerm_network_security_perimeter" "this" {
  for_each = var.network_security_perimeters

  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  name = each.key
}

resource "azurerm_network_security_perimeter_profile" "this" {
  for_each = local.profiles

  name                          = each.value.profile_name
  network_security_perimeter_id = azurerm_network_security_perimeter.this[each.value.perimeter_name].id
}

resource "azurerm_network_security_perimeter_access_rule" "this" {
  for_each = local.access_rules

  name                                  = each.value.name
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.this[each.value.profile_key].id
  direction                             = each.value.rule.direction
  address_prefixes                      = each.value.rule.address_prefixes
  fqdns                                 = each.value.rule.fqdns
  service_tags                          = each.value.rule.service_tags
  subscription_ids                      = each.value.rule.subscription_ids
}

resource "azurerm_network_security_perimeter_association" "this" {
  for_each = local.associations

  name                                  = each.value.name
  network_security_perimeter_profile_id = azurerm_network_security_perimeter_profile.this[each.value.profile_key].id
  resource_id                           = each.value.resource_id
  access_mode                           = each.value.access_mode
}
