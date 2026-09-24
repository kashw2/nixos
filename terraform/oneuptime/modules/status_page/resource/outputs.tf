output "ids" {
  value = { for name, resource in oneuptime_status_page_resource.this : name => resource.id }
}
