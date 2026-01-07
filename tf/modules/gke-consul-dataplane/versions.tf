terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    consul = {
      source  = "hashicorp/consul"
      version = ">= 2.17.0" # Recommend at least 2.17+ for stability
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.5.0"
}

