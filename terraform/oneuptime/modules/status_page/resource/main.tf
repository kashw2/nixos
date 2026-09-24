resource "oneuptime_status_page_resource" "this" {
  for_each = var.monitors

  status_page_id = var.status_page_id
  monitor_id     = each.value
  display_name   = each.key

  show_current_status       = true
  show_uptime_percent       = true
  show_status_history_chart = true
}
