<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure Network Security Perimeter

Network security perimeters with profiles, access rules, and PaaS resource associations.

[![CI](https://github.com/libre-devops/terraform-azurerm-network-security-perimeter/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-network-security-perimeter/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-network-security-perimeter?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-network-security-perimeter/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-network-security-perimeter)](./LICENSE)

---

## Overview

A Network Security Perimeter (NSP) draws a network isolation boundary around PaaS resources (Key Vault,
storage, and others), so their public endpoints only accept traffic that the perimeter's rules allow.
This module takes `network_security_perimeters` keyed by name; each has **profiles**, and each profile
has **access rules** (Inbound/Outbound, by address prefix, subscription, service tag, or FQDN) and
**associations** that bring a PaaS resource inside the perimeter.

Associations default to **Learning** mode (observe, do not block) so onboarding never breaks
connectivity; move them to `Enforced` once the access rules are validated (or `Audit` to log denials).
Perimeter **logs** are shipped with the Libre DevOps `diagnostic-settings` module: pass a perimeter id
from the `ids` output as a diagnostic target. The resource group is passed by id and parsed.

## Usage

```hcl
module "nsp" {
  source  = "libre-devops/network-security-perimeter/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  network_security_perimeters = {
    "nsp-ldo-uks-prd-001" = {
      profiles = {
        "default" = {
          access_rules = {
            "allow-corp-inbound" = { direction = "Inbound", address_prefixes = ["203.0.113.0/24"] }
          }
          associations = {
            # Learning by default; switch to Enforced once validated.
            "kv" = { resource_id = module.key_vault.id }
          }
        }
      }
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - a single perimeter with one profile and an inbound access
  rule.
- [`examples/complete`](./examples/complete) - a perimeter with inbound and outbound rules, a Log
  Analytics workspace associated in Enforced mode, and perimeter logs shipped to another workspace via
  the `diagnostic-settings` module.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0, < 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_perimeter.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_perimeter) | resource |
| [azurerm_network_security_perimeter_access_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_perimeter_access_rule) | resource |
| [azurerm_network_security_perimeter_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_perimeter_association) | resource |
| [azurerm_network_security_perimeter_profile.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_perimeter_profile) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_location"></a> [location](#input\_location) | Azure region for the network security perimeters. | `string` | n/a | yes |
| <a name="input_network_security_perimeters"></a> [network\_security\_perimeters](#input\_network\_security\_perimeters) | Network security perimeters to create, keyed by perimeter name. Each perimeter has profiles (keyed<br/>by name); each profile has access\_rules and associations (both keyed by name).<br/><br/>access\_rules: direction is Inbound or Outbound; give at least one selector: address\_prefixes,<br/>subscription\_ids, service\_tags (Inbound), or fqdns (Outbound).<br/><br/>associations: bring a PaaS resource (by resource\_id) inside the perimeter. access\_mode defaults to<br/>Learning (observe, do not block) for safe onboarding; set Enforced once your access rules are<br/>validated, or Audit to log denials without blocking. | <pre>map(object({<br/>    profiles = optional(map(object({<br/>      access_rules = optional(map(object({<br/>        direction        = string<br/>        address_prefixes = optional(list(string))<br/>        fqdns            = optional(list(string))<br/>        service_tags     = optional(list(string))<br/>        subscription_ids = optional(list(string))<br/>      })), {})<br/>      associations = optional(map(object({<br/>        resource_id = string<br/>        access_mode = optional(string, "Learning")<br/>      })), {})<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource id of the resource group to create the perimeters in. The name and subscription are parsed from it (pass the rg module's ids output). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the perimeters. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_rule_ids"></a> [access\_rule\_ids](#output\_access\_rule\_ids) | Map of "<perimeter>\|<profile>\|<rule>" to the access rule id. |
| <a name="output_association_ids"></a> [association\_ids](#output\_association\_ids) | Map of "<perimeter>\|<profile>\|<association>" to the association id. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of perimeter name to its resource id (pass to the diagnostic-settings module to ship perimeter logs). |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of perimeter name to a { name, id } object, for passing where both are needed together. |
| <a name="output_names"></a> [names](#output\_names) | The perimeter names. |
| <a name="output_profile_ids"></a> [profile\_ids](#output\_profile\_ids) | Map of "<perimeter>\|<profile>" to the profile id. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name parsed from resource\_group\_id. |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription id parsed from resource\_group\_id. |
| <a name="output_tags"></a> [tags](#output\_tags) | The tags applied to the perimeters. |
<!-- END_TF_DOCS -->
