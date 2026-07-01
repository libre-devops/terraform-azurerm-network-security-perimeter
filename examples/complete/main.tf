locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  nsp_name = "nsp-${var.short}-${var.loc}-${terraform.workspace}-002"
  law_name = "log-${var.short}-${var.loc}-${terraform.workspace}-002"
  kv_name  = "kv-${var.short}-${var.loc}-${terraform.workspace}-002"
}

data "azurerm_client_config" "current" {}

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

# Workspace to receive the perimeter logs.
module "log_analytics" {
  source  = "libre-devops/log-analytics-workspace/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  log_analytics_workspaces = { (local.law_name) = {} }
}

# A PaaS resource to bring inside the perimeter.
resource "azurerm_key_vault" "this" {
  name                = local.kv_name
  location            = local.location
  resource_group_name = module.rg.names[local.rg_name]
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  tags                = module.tags.tags

  # Deny by default (Azure services may bypass); purge protection off so this example vault is
  # destroyable (see the Trivy waiver for AZU-0016).
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

# Complete call: a perimeter with inbound and outbound rules, and the Key Vault associated in Learning
# mode (observe, do not block) so onboarding is non-breaking.
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
            "kv" = {
              resource_id = azurerm_key_vault.this.id
              access_mode = "Learning"
            }
          }
        }
      }
    }
  }
}

# Ship the perimeter's access logs to the workspace via the diagnostic-settings module. Metrics are
# disabled because the perimeter exposes logs, not metrics.
module "diagnostics" {
  source  = "libre-devops/diagnostic-settings/azurerm"
  version = "~> 4.0"

  log_analytics_workspace_id = module.log_analytics.workspace_ids[local.law_name]

  diagnostic_settings = {
    "nsp" = {
      target_resource_id = module.nsp.ids[local.nsp_name]
      enable_all_metrics = false
    }
  }
}
