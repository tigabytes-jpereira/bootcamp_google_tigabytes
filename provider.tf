terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" # Use a versão mais recente compatível
    }
  }
}

provider "google" {
  project = "SEU_PROJETO_GCP" # Substitua pelo ID do seu projeto GCP
  region  = "southamerica-east1" # Região de São Paulo (ou a sua preferida)
  zone    = "southamerica-east1-a" # Zona dentro da região (opcional, dependendo do recurso)
}