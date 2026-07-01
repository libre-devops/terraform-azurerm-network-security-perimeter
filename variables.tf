variable "location" {
  description = "Azure region for the network security perimeters."
  type        = string
}

variable "network_security_perimeters" {
  description = <<-EOT
    Network security perimeters to create, keyed by perimeter name. Each perimeter has profiles (keyed
    by name); each profile has access_rules and associations (both keyed by name).

    access_rules: direction is Inbound or Outbound; give at least one selector: address_prefixes,
    subscription_ids, service_tags (Inbound), or fqdns (Outbound).

    associations: bring a PaaS resource (by resource_id) inside the perimeter. access_mode defaults to
    Learning (observe, do not block) for safe onboarding; set Enforced once your access rules are
    validated, or Audit to log denials without blocking.
  EOT
  type = map(object({
    profiles = optional(map(object({
      access_rules = optional(map(object({
        direction        = string
        address_prefixes = optional(list(string))
        fqdns            = optional(list(string))
        service_tags     = optional(list(string))
        subscription_ids = optional(list(string))
      })), {})
      associations = optional(map(object({
        resource_id = string
        access_mode = optional(string, "Learning")
      })), {})
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for nsp in values(var.network_security_perimeters) : alltrue([
        for prof in values(nsp.profiles) : alltrue([
          for r in values(prof.access_rules) : contains(["Inbound", "Outbound"], r.direction)
        ])
      ])
    ])
    error_message = "Each access rule direction must be Inbound or Outbound."
  }

  validation {
    condition = alltrue([
      for nsp in values(var.network_security_perimeters) : alltrue([
        for prof in values(nsp.profiles) : alltrue([
          for r in values(prof.access_rules) :
          length(coalesce(r.address_prefixes, [])) + length(coalesce(r.fqdns, [])) + length(coalesce(r.service_tags, [])) + length(coalesce(r.subscription_ids, [])) > 0
        ])
      ])
    ])
    error_message = "Each access rule needs at least one selector: address_prefixes, fqdns, service_tags, or subscription_ids."
  }

  validation {
    condition = alltrue([
      for nsp in values(var.network_security_perimeters) : alltrue([
        for prof in values(nsp.profiles) : alltrue([
          for a in values(prof.associations) : contains(["Learning", "Enforced", "Audit"], a.access_mode)
        ])
      ])
    ])
    error_message = "Each association access_mode must be Learning, Enforced, or Audit."
  }
}

variable "resource_group_id" {
  description = "Resource id of the resource group to create the perimeters in. The name and subscription are parsed from it (pass the rg module's ids output)."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.resource_group_id).resource_type, "") == "resourceGroups"
    error_message = "resource_group_id must be a resource group id of the form /subscriptions/<sub>/resourceGroups/<name>."
  }
}

variable "tags" {
  description = "Tags to apply to the perimeters."
  type        = map(string)
  default     = {}
}
