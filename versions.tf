terraform {
  required_providers {
    hetznerdns = {
      source = "germanbrew/hetznerdns"
      version = "3.0.0"  # Replace with latest version
    }
  }
}

provider "hetznerdns" {
api_token = local.api.auth.api_token
}

