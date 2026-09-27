variable "probe_id" {
  type = string
}

variable "snmp_v3_username" {
  type = string
}

variable "snmp_v3_auth_key" {
  type      = string
  sensitive = true
}

variable "snmp_v3_priv_key" {
  type      = string
  sensitive = true
}

variable "scan_cidr" {
  type = string
}

variable "import_cidr" {
  type = string
}

variable "gateway" {
  type = string
}
