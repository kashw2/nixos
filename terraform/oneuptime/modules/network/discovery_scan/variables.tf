variable "name" {
  type = string
}

variable "probe_id" {
  type = string
}

variable "cidr" {
  type = string
}

variable "username" {
  type = string
}

variable "auth_key" {
  type      = string
  sensitive = true
}

variable "priv_key" {
  type      = string
  sensitive = true
}

variable "port" {
  type    = number
  default = 161
}

variable "rescan_interval_in_minutes" {
  type    = number
  default = 60
}
