locals {
  location = lookup(var.regions, var.loc, "uksouth")
  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  nsp_name = "nsp-${var.short}-${var.loc}-${terraform.workspace}-001"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# Minimal call: one perimeter with a default profile and a single inbound access rule.
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
          }
        }
      }
    }
  }
}
