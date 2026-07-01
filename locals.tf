locals {
  rg                  = provider::azurerm::parse_resource_id(var.resource_group_id)
  resource_group_name = local.rg.resource_group_name

  # Flatten profiles to one map keyed "<perimeter>|<profile>".
  profiles = merge([
    for nsp_name, nsp in var.network_security_perimeters : {
      for prof_name, prof in nsp.profiles : "${nsp_name}|${prof_name}" => {
        perimeter_name = nsp_name
        profile_name   = prof_name
      }
    }
  ]...)

  # Flatten access rules to one map keyed "<perimeter>|<profile>|<rule>".
  access_rules = merge([
    for nsp_name, nsp in var.network_security_perimeters : {
      for pair in flatten([
        for prof_name, prof in nsp.profiles : [
          for rule_name, rule in prof.access_rules : {
            key            = "${nsp_name}|${prof_name}|${rule_name}"
            perimeter_name = nsp_name
            profile_name   = prof_name
            profile_key    = "${nsp_name}|${prof_name}"
            name           = rule_name
            rule           = rule
          }
        ]
      ]) : pair.key => pair
    }
  ]...)

  # Flatten associations to one map keyed "<perimeter>|<profile>|<association>".
  associations = merge([
    for nsp_name, nsp in var.network_security_perimeters : {
      for pair in flatten([
        for prof_name, prof in nsp.profiles : [
          for assoc_name, assoc in prof.associations : {
            key         = "${nsp_name}|${prof_name}|${assoc_name}"
            profile_key = "${nsp_name}|${prof_name}"
            name        = assoc_name
            resource_id = assoc.resource_id
            access_mode = assoc.access_mode
          }
        ]
      ]) : pair.key => pair
    }
  ]...)
}
