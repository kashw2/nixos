variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "hostname" {
  type = string
}

variable "probe_id" {
  type = string
}

variable "snmp_credential_profile_id" {
  type = string
}

variable "polling_interval_in_minutes" {
  type    = number
  default = 5
}
