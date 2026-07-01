# Plan-time tests for the module. The azurerm provider is mocked, so no credentials, no
# features block, and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001"
  location          = "uksouth"

  network_security_perimeters = {
    "nsp-ldo-uks-tst-001" = {
      profiles = {
        "default" = {
          access_rules = {
            "allow-corp" = {
              direction        = "Inbound"
              address_prefixes = ["10.0.0.0/8"]
            }
          }
        }
      }
    }
  }
}

run "creates_perimeter_profile_and_rule" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_perimeter.this) == 1 && length(azurerm_network_security_perimeter_profile.this) == 1 && length(azurerm_network_security_perimeter_access_rule.this) == 1
    error_message = "A perimeter, a profile, and an access rule should each be created."
  }

  assert {
    condition     = output.resource_group_name == "rg-ldo-uks-tst-001"
    error_message = "resource_group_name should be parsed from resource_group_id."
  }
}

run "associations_default_to_learning" {
  command = plan

  variables {
    network_security_perimeters = {
      "nsp-ldo-uks-tst-002" = {
        profiles = {
          "default" = {
            associations = {
              "kv" = { resource_id = "/subscriptions/0000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv-ldo-uks-tst-001" }
            }
          }
        }
      }
    }
  }

  assert {
    condition     = one(values(azurerm_network_security_perimeter_association.this)).access_mode == "Learning"
    error_message = "associations should default to Learning mode."
  }
}

run "rejects_invalid_direction" {
  command = plan

  variables {
    network_security_perimeters = {
      "nsp-bad" = {
        profiles = {
          "default" = {
            access_rules = {
              "bad" = { direction = "Sideways", address_prefixes = ["10.0.0.0/8"] }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.network_security_perimeters]
}

run "rejects_access_rule_without_selector" {
  command = plan

  variables {
    network_security_perimeters = {
      "nsp-bad" = {
        profiles = {
          "default" = {
            access_rules = {
              "empty" = { direction = "Inbound" }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.network_security_perimeters]
}

run "rejects_invalid_access_mode" {
  command = plan

  variables {
    network_security_perimeters = {
      "nsp-bad" = {
        profiles = {
          "default" = {
            associations = {
              "kv" = { resource_id = "/subscriptions/0000/resourceGroups/rg/providers/Microsoft.KeyVault/vaults/kv", access_mode = "Blocking" }
            }
          }
        }
      }
    }
  }

  expect_failures = [var.network_security_perimeters]
}
