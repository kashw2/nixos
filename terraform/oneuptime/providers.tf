terraform {
  required_version = ">= 1.6"

  required_providers {
    oneuptime = {
      source  = "oneuptime/oneuptime"
      version = "14.0.6"
    }
  }

  encryption {
    key_provider "pbkdf2" "sops" {
      passphrase               = var.NIXOS_STATE_PASSPHRASE
      encrypted_metadata_alias = "oneuptime"
    }

    method "aes_gcm" "sops" {
      keys = key_provider.pbkdf2.sops
    }

    state {
      method   = method.aes_gcm.sops
      enforced = true
    }

    plan {
      method   = method.aes_gcm.sops
      enforced = true
    }
  }
}

provider "oneuptime" {
  oneuptime_url = "http://oneuptime.media.local"
}
