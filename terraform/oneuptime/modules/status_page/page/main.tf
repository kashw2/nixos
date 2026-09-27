resource "oneuptime_status_page" "this" {
  name             = var.name
  page_title       = var.page_title
  page_description = var.page_description

  show_overall_uptime_percent_on_status_page = true
  show_uptime_history_in_days                = 90
  enable_search_engine_indexing              = false
}
