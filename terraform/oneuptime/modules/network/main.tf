module "credentials" {
  source = "./credential_profile"

  name        = "OpenWrt SNMPv3"
  description = "SNMPv3 authPriv read-only user on the OpenWrt router"
  username    = var.snmp_v3_username
  auth_key    = var.snmp_v3_auth_key
  priv_key    = var.snmp_v3_priv_key
}

module "gateway" {
  source = "./device"

  name        = "OpenWrt"
  description = "Home router - OpenWrt 25.12.5 on mvebu/cortexa9"
  hostname    = var.gateway

  probe_id                   = var.probe_id
  snmp_credential_profile_id = module.credentials.id
}

module "lan_sweep" {
  source = "./discovery_scan"

  name     = "LAN Sweep"
  probe_id = var.probe_id
  cidr     = var.scan_cidr
  username = var.snmp_v3_username
  auth_key = var.snmp_v3_auth_key
  priv_key = var.snmp_v3_priv_key
}

module "infrastructure" {
  source = "./auto_import_rule"

  name            = "Import LAN Infrastructure"
  description     = "Auto-import static-range hosts (192.168.1.0/27), including ping-only NixOS hosts"
  ip_match_target = var.import_cidr
}

moved {
  from = oneuptime_snmp_credential_profile.this
  to   = module.credentials.oneuptime_snmp_credential_profile.this
}

moved {
  from = oneuptime_network_device.gateway
  to   = module.gateway.oneuptime_network_device.this
}

moved {
  from = oneuptime_network_device_discovery_scan.lan
  to   = module.lan_sweep.oneuptime_network_device_discovery_scan.this
}

moved {
  from = oneuptime_network_device_auto_import_rule.infrastructure
  to   = module.infrastructure.oneuptime_network_device_auto_import_rule.this
}
