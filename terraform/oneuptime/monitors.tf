resource "oneuptime_monitor" "agent" {
  for_each = var.hosts

  name         = each.key
  monitor_type = "Server"
  description  = "Infrastructure agent metrics for ${each.key}"
}
