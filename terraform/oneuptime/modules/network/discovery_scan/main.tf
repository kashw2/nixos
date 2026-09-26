resource "oneuptime_network_device_discovery_scan" "this" {
  name     = var.name
  probe_id = var.probe_id
  cidr     = var.cidr

  is_recurring               = true
  rescan_interval_in_minutes = var.rescan_interval_in_minutes

  is_snmp_enabled        = true
  snmp_version           = "v3"
  snmp_port              = var.port
  snmp_v3_security_level = "authPriv"
  snmp_v3_username       = var.username
  snmp_v3_auth_protocol  = "SHA256"
  snmp_v3_auth_key       = var.auth_key
  snmp_v3_priv_protocol  = "AES"
  snmp_v3_priv_key       = var.priv_key
}
