resource "oneuptime_network_device_auto_import_rule" "this" {
  name        = var.name
  description = var.description

  is_enabled              = true
  ip_match_target         = var.ip_match_target
  include_ping_only_hosts = var.include_ping_only_hosts
  is_exclusion            = var.is_exclusion
}
