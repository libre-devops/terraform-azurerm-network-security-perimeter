output "association_ids" {
  description = "The perimeter association ids."
  value       = module.nsp.association_ids
}

output "diagnostic_setting_ids" {
  description = "The diagnostic setting ids shipping perimeter logs to the workspace."
  value       = module.diagnostics.diagnostic_setting_ids
}

output "perimeter_ids" {
  description = "Map of perimeter name to resource id."
  value       = module.nsp.ids
}

output "tags" {
  description = "The tags applied to the resources."
  value       = module.tags.tags
}
