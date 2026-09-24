terraform {
  required_version = ">= 1.6"

  required_providers {
    oneuptime = {
      source  = "oneuptime/oneuptime"
      version = "13.0.0"
    }
  }
}

provider "oneuptime" {
  oneuptime_url = "http://oneuptime.media.local"
}
