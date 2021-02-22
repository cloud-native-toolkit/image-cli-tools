terraform {
  required_version = "> 0.12.0"
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.1.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.0.2"
    }
    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
  }
}
