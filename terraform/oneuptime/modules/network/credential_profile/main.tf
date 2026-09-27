resource "oneuptime_snmp_credential_profile" "this" {
  name        = var.name
  description = var.description

  snmp_version           = "v3"
  snmp_port              = var.port
  snmp_v3_security_level = "authPriv"
  snmp_v3_username       = var.username
  snmp_v3_auth_protocol  = "SHA256"
  snmp_v3_auth_key       = var.auth_key
  snmp_v3_priv_protocol  = "AES"
  snmp_v3_priv_key       = var.priv_key
}
