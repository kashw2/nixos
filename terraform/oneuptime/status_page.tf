resource "oneuptime_status_page" "vhosts" {
  name             = "Services"
  page_title       = "Service Status"
  page_description = "Uptime for the services behind nginx on media"

  show_overall_uptime_percent_on_status_page = true
  show_uptime_history_in_days                = 90
  enable_search_engine_indexing              = false
}
