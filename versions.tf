terraform {
  required_providers {
    hetznerdns = {
      source = "germanbrew/hetznerdns"
      version = "3.3.3"
    }
  }
}

provider "hetznerdns" {
  api_token = local.api.auth.api_token
}