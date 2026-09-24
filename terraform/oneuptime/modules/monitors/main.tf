resource "oneuptime_monitor" "agent" {
  for_each = var.hosts

  name         = each.key
  monitor_type = "Server"
  description  = "Infrastructure agent metrics for ${each.key}"
}

resource "oneuptime_monitor" "vhost" {
  for_each = var.vhosts

  name         = each.key
  monitor_type = "Website"
  description  = "nginx vhost on media"

  monitor_steps = [
    {
      monitor_destination      = "http://${each.key}"
      monitor_destination_type = "URL"
      request_type             = "GET"
      criteria = [
        {
          name             = "Check if online"
          filter_condition = "All"
          filters = [
            {
              check_on = "Is Online"
            }
          ]
        }
      ]
    }
  ]
}
