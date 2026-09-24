resource "oneuptime_status_page_resource" "vhost" {
  for_each = var.vhosts

  status_page_id = oneuptime_status_page.vhosts.id
  monitor_id     = oneuptime_monitor.vhost[each.key].id
  display_name   = each.key

  show_current_status       = true
  show_uptime_percent       = true
  show_status_history_chart = true
}
