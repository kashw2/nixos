resource "oneuptime_runner" "media" {
  name        = "media"
  key         = var.ONEUPTIME_RUNNER_KEY
  description = "OneUptime runner on media"

  can_run_runbooks       = true
  can_run_code_fix_tasks = true
}
