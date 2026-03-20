locals {
  nsg_rules_flat = flatten([
    for nsg_name, nsg in var.nsgs : [
      for rule in nsg.rules : merge(rule, {
        nsg_name = nsg_name
      })
    ]
  ])
}
