resource "oneuptime_network_device" "this" {
  name        = var.name
  description = var.description
  hostname    = var.hostname

  probe_id                   = var.probe_id
  snmp_credential_profile_id = var.snmp_credential_profile_id

  is_polling_enabled          = true
  polling_interval_in_minutes = var.polling_interval_in_minutes
  walk_interfaces             = true
  collect_endpoints           = true
}
