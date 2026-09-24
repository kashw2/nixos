resource "oneuptime_monitor" "agent" {
  for_each = var.hosts

  name         = each.key
  monitor_type = "Server"
  description  = "Infrastructure agent metrics for ${each.key}"

  monitor_steps = [
    {
      criteria = [
        {
          name                  = "Online"
          filter_condition      = "All"
          change_monitor_status = true
          monitor_status_id     = data.oneuptime_monitor_status.operational.id
          filters = [
            {
              check_on    = "Is Online"
              filter_type = "True"
            }
          ]
        },
        {
          name                  = "Offline"
          filter_condition      = "All"
          change_monitor_status = true
          monitor_status_id     = data.oneuptime_monitor_status.offline.id
          filters = [
            {
              check_on    = "Is Online"
              filter_type = "False"
            }
          ]
        },
      ]
    }
  ]
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
          name                  = "Online"
          filter_condition      = "All"
          change_monitor_status = true
          monitor_status_id     = data.oneuptime_monitor_status.operational.id
          filters = [
            {
              check_on    = "Is Online"
              filter_type = "True"
            }
          ]
        },
        {
          name                  = "Offline"
          filter_condition      = "All"
          change_monitor_status = true
          monitor_status_id     = data.oneuptime_monitor_status.offline.id
          filters = [
            {
              check_on    = "Is Online"
              filter_type = "False"
            }
          ]
        },
      ]
    }
  ]
}
