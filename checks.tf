# check blocks run after every plan and apply and emit a warning (without blocking) when an
# invariant is violated. They are the place to enforce module-wide consistency.

# The module does nothing without at least one perimeter.
check "has_perimeters" {
  assert {
    condition     = length(var.network_security_perimeters) > 0
    error_message = "No network_security_perimeters were supplied, so this module creates nothing."
  }
}

# Access rules and associations only take effect through a profile; warn if a perimeter has neither.
check "perimeters_have_profiles" {
  assert {
    condition     = alltrue([for nsp in values(var.network_security_perimeters) : length(nsp.profiles) > 0])
    error_message = "A perimeter with no profiles has nowhere to attach access rules or associations; add at least one profile."
  }
}
