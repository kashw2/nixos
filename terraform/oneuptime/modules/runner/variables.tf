variable "key" {
  type      = string
  sensitive = true
}

variable "name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}
