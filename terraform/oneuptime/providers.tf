terraform {
  required_version = ">= 1.6"

  required_providers {
    oneuptime = {
      source  = "oneuptime/oneuptime"
      version = "14.0.6"
    }
  }
}

provider "oneuptime" {
  oneuptime_url = "http://oneuptime.media.local"
}
