terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Use a versão mais recente compatível
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 6.0" # Use a versão mais recente compatível
    }
  }
}
