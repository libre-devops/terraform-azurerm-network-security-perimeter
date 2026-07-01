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
- [`examples/complete`](./examples/complete) - a perimeter with inbound and outbound rules, a Key Vault
  association (Learning mode), and perimeter logs shipped to a Log Analytics workspace via the
  `diagnostic-settings` module.

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
| AVD-AZU-0016 | Example Key Vault (`examples/complete/main.tf`) | Purge protection not enabled | The example vault is a disposable perimeter-association target; purge protection is left off so the self-test can tear it down. Real vaults use the Libre DevOps key-vault module (purge protection on). |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.
