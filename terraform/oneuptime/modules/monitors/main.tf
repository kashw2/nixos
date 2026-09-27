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

resource "oneuptime_monitor" "postgres" {
  name         = "PostgreSQL"
  monitor_type = "Database"
  description  = "PostgreSQL health on media"

  monitor_steps = [
    {
      database_monitor = jsonencode({
        databaseType          = "PostgreSQL"
        host                  = "127.0.0.1"
        port                  = 5432
        databaseName          = "oneuptime"
        username              = "oneuptime"
        password              = ""
        useSsl                = false
        rejectUnauthorizedSsl = false
      })

      criteria = [
        {
          name                  = "Online"
          filter_condition      = "All"
          is_enabled            = true
          change_monitor_status = true
          create_incidents      = false
          create_alerts         = false
          monitor_status_id     = data.oneuptime_monitor_status.operational.id
          filters = [
            {
              check_on    = "Database Is Online"
              filter_type = "True"
            }
          ]
        },
        {
          name                  = "Offline"
          filter_condition      = "All"
          is_enabled            = true
          change_monitor_status = true
          create_incidents      = false
          create_alerts         = false
          monitor_status_id     = data.oneuptime_monitor_status.offline.id
          filters = [
            {
              check_on    = "Database Is Online"
              filter_type = "False"
            }
          ]
        },
      ]
    }
  ]
}

resource "oneuptime_monitor" "clickhouse" {
  name         = "ClickHouse"
  monitor_type = "Port"
  description  = "ClickHouse HTTP interface reachability on media"

  monitor_steps = [
    {
      monitor_destination      = "127.0.0.1"
      monitor_destination_type = "IP"
      port                     = 8123

      criteria = [
        {
          name                  = "Online"
          filter_condition      = "All"
          is_enabled            = true
          change_monitor_status = true
          create_incidents      = false
          create_alerts         = false
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
          is_enabled            = true
          change_monitor_status = true
          create_incidents      = false
          create_alerts         = false
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

moved {
  from = oneuptime_monitor.postgres_connections
  to   = oneuptime_monitor.postgres
}

moved {
  from = oneuptime_monitor.clickhouse_disk
  to   = oneuptime_monitor.clickhouse
}
