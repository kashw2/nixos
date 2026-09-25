variable "name" {
  type = string
}

variable "description" {
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
