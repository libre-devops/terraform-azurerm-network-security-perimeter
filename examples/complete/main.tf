locals {
  location       = lookup(var.regions, var.loc, "uksouth")
  rg_name        = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  nsp_name       = "nsp-${var.short}-${var.loc}-${terraform.workspace}-002"
  law_logs_name  = "log-${var.short}-${var.loc}-${terraform.workspace}-002"
  law_assoc_name = "log-${var.short}-${var.loc}-${terraform.workspace}-003"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  environment     = "prd"
  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-network-security-perimeter" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# Two workspaces: one receives the perimeter logs, the other is the PaaS resource brought inside the
# perimeter (Log Analytics is a perimeter-supported resource, per the provider docs).
module "log_analytics" {
  source  = "libre-devops/log-analytics-workspace/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  log_analytics_workspaces = {
    (local.law_logs_name) = {}
    # The workspace brought inside the perimeter has a system-assigned identity: Azure warns
    # (MissingIdentityConfiguration) that intra-perimeter communication is only authenticated via a
    # managed identity, so associated resources should have one.
    (local.law_assoc_name) = { identity = { type = "SystemAssigned" } }
  }
}

# Complete call: a perimeter with inbound and outbound rules, with a workspace associated in Enforced
# mode (the perimeter actively gates the resource's public endpoints). Onboard in Learning first, then
# move to Enforced once the access rules are validated.
module "nsp" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  network_security_perimeters = {
    (local.nsp_name) = {
      profiles = {
        "default" = {
          access_rules = {
            "allow-corp-inbound" = {
              direction        = "Inbound"
              address_prefixes = ["203.0.113.0/24"]
            }
            "allow-updates-outbound" = {
              direction = "Outbound"
              fqdns     = ["packages.microsoft.com"]
            }
          }
          associations = {
            "law" = {
              resource_id = module.log_analytics.workspace_ids[local.law_assoc_name]
              access_mode = "Enforced"
            }
          }
        }
      }
    }
  }
}

# Ship the perimeter's access logs to the logs workspace via the diagnostic-settings module. Metrics
# are disabled because the perimeter exposes logs, not metrics.
module "diagnostics" {
  source  = "libre-devops/diagnostic-settings/azurerm"
  version = "~> 4.0"

  log_analytics_workspace_id = module.log_analytics.workspace_ids[local.law_logs_name]

  diagnostic_settings = {
    "nsp" = {
      target_resource_id = module.nsp.ids[local.nsp_name]
      enable_all_metrics = false
    }
  }
}
