terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    consul = {            
      source  = "hashicorp/consul"
      version = "~> 2.20"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.0"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 4.21.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    http = {             
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}