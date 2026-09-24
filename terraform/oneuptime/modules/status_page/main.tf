module "vhosts" {
  source = "./page"

  name             = "Services"
  page_title       = "Service Status"
  page_description = "Uptime for the services behind nginx on media"
}

module "vhost_resources" {
  source = "./resource"

  status_page_id = module.vhosts.id
  monitors       = var.vhost_monitors
}

module "hosts" {
  source = "./page"

  name             = "Hosts"
  page_title       = "Host Status"
  page_description = "Uptime for the machines reporting through the OneUptime infrastructure agent"
}

module "host_resources" {
  source = "./resource"

  status_page_id = module.hosts.id
  monitors       = var.host_monitors
}
