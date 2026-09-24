resource "oneuptime_probe" "this" {
  key           = var.key
  name          = var.name
  description   = var.description
  probe_version = var.probe_version

  should_auto_enable_probe_on_new_monitors = true
}
