resource "nomad_job" "prometheus" {
  jobspec = <<EOF
job "prometheus" {
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    count = 1

    network {
      port "prometheus_ui" {
        static = 9090
      }
    }

    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    ephemeral_disk {
      size = 300
    }

    task "prometheus" {
      template {
        change_mode = "noop"
        destination = "local/prometheus.yml"

        data = <<EOH
---
global:
  scrape_interval:     5s
  evaluation_interval: 5s

scrape_configs:

  - job_name: 'nomad_metrics'

    consul_sd_configs:
    - server: '{{ env "NOMAD_IP_prometheus_ui" }}:8500'
      services: ['nomad-client', 'nomad']

    relabel_configs:
    - source_labels: ['__meta_consul_tags']
      regex: '(.*)http(.*)'
      action: keep

    scrape_interval: 5s
    metrics_path: /v1/metrics
    params:
      format: ['prometheus']
EOH
      }

      driver = "docker"

      config {
        image = "prom/prometheus:latest"

        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
        ]

        ports = ["prometheus_ui"]
      }

      service {
        name = "prometheus"
        tags = ["urlprefix-/"]
        port = "prometheus_ui"

        check {
          name     = "prometheus_ui port alive"
          type     = "http"
          path     = "/-/healthy"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
EOF
}

resource "null_resource" "autoscaler" {
  provisioner "local-exec" {
    command = "export NOMAD_ADDR=$NA && nomad-pack list && nomad-pack run nomad_autoscaler --registry=community --parser-v1"
  
    environment = {
        NA = "http://${module.nomad.fqdn}:4646"
    }
  }
  
  depends_on = [ nomad_job.prometheus ]
}

resource "nomad_job" "hashicups" {
  jobspec = <<EOF
variable "datacenters" {
  description = "A list of datacenters in the region which are eligible for task placement."
  type        = list(string)
  default     = ["*"]
}

variable "region" {
  description = "The region where the job should be placed."
  type        = string
  default     = "global"
}

variable "frontend_version" {
  description = "Docker version tag"
  default = "v1.0.4"
}

variable "public_api_version" {
  description = "Docker version tag"
  default = "v0.0.7"
}

variable "payments_version" {
  description = "Docker version tag"
  default = "v0.0.12"
}

variable "product_api_version" {
  description = "Docker version tag"
  default = "v0.0.21"
}

variable "product_api_db_version" {
  description = "Docker version tag"
  default = "v0.0.20"
}

variable "postgres_db" {
  description = "Postgres DB name"
  default = "products"
}

variable "postgres_user" {
  description = "Postgres DB User"
  default = "postgres"
}

variable "postgres_password" {
  description = "Postgres DB Password"
  default = "password"
}

variable "product_api_port" {
  description = "Product API Port"
  default = 9090
}

variable "frontend_port" {
  description = "Frontend Port"
  default = 3000
}

variable "payments_api_port" {
  description = "Payments API Port"
  default = 8080
}

variable "public_api_port" {
  description = "Public API Port"
  default = 8081
}

variable "nginx_port" {
  description = "Nginx Port"
  default = 80
}

# Begin Job Spec

job "hashicups" {
  type   = "service"
  region = var.region
  datacenters = var.datacenters

  group "db" {
    network {
      port "db" {
        to = 5432
      }
    }
    task "db" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      service {
        name = "database"
        provider = "consul"
        port = "db"
        # Update to something like attr.unique.platform.aws.public-ipv4
        # if running on local on AWS or similar
        address  = attr.unique.network.ip-address
      }
      meta {
        service = "database"
      }
      config {
        image   = "hashicorpdemoapp/product-api-db:${var.product_api_db_version}"
        ports = ["db"]
      }
      env {
        POSTGRES_DB       = "products"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "password"
      }
    }
  }

  group "product-api" {
    network {
      port "product-api" {
        to = var.product_api_port
      }
    }
    task "product-api" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      service {
        name = "product-api"
        provider = "consul"
        port = "product-api"
        address  = attr.unique.network.ip-address
      }
      meta {
        service = "product-api"
      }
      config {
        image   = "hashicorpdemoapp/product-api:${var.product_api_version}"
        ports = ["product-api"]
      }
      template {
        data        = <<EOH
{{ range service "database" }}
DB_CONNECTION="host={{ .Address }} port={{ .Port }} user=${var.postgres_user} password=${var.postgres_password} dbname=${var.postgres_db} sslmode=disable"
BIND_ADDRESS = "{{ env "NOMAD_IP_product-api" }}:{{ env "NOMAD_PORT_product-api" }}"
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }
      resources {
        cpu    = 500
        memory = 512
      }
    }
  }

  group "frontend" {
    network {
      port "frontend" {
        to = var.frontend_port
      }
    }
    task "frontend" {
      driver = "docker"
      service {
        name = "frontend"
        provider = "consul"
        port = "frontend"
        address  = attr.unique.network.ip-address
      }
      meta {
        service = "frontend"
      }
      template {
        data        = <<EOH
{{ range service "public-api" }}
NEXT_PUBLIC_PUBLIC_API_URL="http://{{ .Address }}:{{ .Port }}"
NEXT_PUBLIC_FOOTER_FLAG="{{ env "NOMAD_ALLOC_NAME" }}"
{{ end }}
PORT="{{ env "NOMAD_PORT_frontend" }}"
EOH
        destination = "local/env.txt"
        env         = true
      }
      config {
        image   = "hashicorpdemoapp/frontend:${var.frontend_version}"
        ports = ["frontend"]
      }
    }
  }

  group "payments-api" {
    network {
      port "payments-api" {
        to = var.payments_api_port
      }
    }
    task "payments-api" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }
      driver = "docker"
      service {
        name = "payments-api"
        provider = "consul"
        port = "payments-api"
        address  = attr.unique.network.ip-address
      }
      meta {
        service = "payments-api"
      }
      config {
        image   = "hashicorpdemoapp/payments:${var.payments_version}"
        ports = ["payments-api"]
      }
      template {
        data        = <<EOH
server.port="{{ env "NOMAD_PORT_payments_api" }}"
EOH
        destination = "/application.properties"
      }
      resources {
        cpu    = 500
        memory = 512
      }

    }
  }

  group "public-api" {
    network {
      port "public-api" {
        to = var.public_api_port
      }
    }
    task "public-api" {
      driver = "docker"
      service {
        name = "public-api"
        provider = "consul"
        port = "public-api"
        address  = attr.unique.network.ip-address
      }
      meta {
        service = "public-api"
      }
      config {
        image   = "hashicorpdemoapp/public-api:${var.public_api_version}"
        ports = ["public-api"] 
      }
      template {
        data        = <<EOH
BIND_ADDRESS = ":${var.public_api_port}"
{{ range service "product-api" }}
PRODUCT_API_URI = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
{{ range service "payments-api" }}
PAYMENT_API_URI = "http://{{ .Address }}:{{ .Port }}"
{{ end }}
EOH
        destination = "local/env.txt"
        env         = true
      }
    }
  }

  group "nginx" {
    network {
      port "nginx" {
        static = var.nginx_port
      }
    }
    task "nginx" {
      driver = "docker"
      service {
        name = "nginx"
        provider = "consul"
        port = "nginx"
        address  = attr.unique.network.ip-address
      }
      meta {
        service = "nginx-reverse-proxy"
      }
      config {
        image = "nginx:alpine"
        ports = ["nginx"]
        mount {
          type   = "bind"
          source = "local/default.conf"
          target = "/etc/nginx/conf.d/default.conf"
        }
      }
      template {
        data =  <<EOF
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=STATIC:10m inactive=7d use_temp_path=off;
upstream frontend_upstream {
  {{ range service "frontend" }}
    server {{ .Address }}:{{ .Port }};
  {{ end }}
}
server {
  listen {{ env "NOMAD_PORT_nginx" }};
  server_name {{ env "NOMAD_IP_nginx" }};
  server_tokens off;
  gzip on;
  gzip_proxied any;
  gzip_comp_level 4;
  gzip_types text/css application/javascript image/svg+xml;
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection 'upgrade';
  proxy_set_header Host $host;
  proxy_cache_bypass $http_upgrade;
  location /_next/static {
    proxy_cache STATIC;
    proxy_pass http://frontend_upstream;
    # For testing cache - remove before deploying to production
    add_header X-Cache-Status $upstream_cache_status;
  }
  location /static {
    proxy_cache STATIC;
    proxy_ignore_headers Cache-Control;
    proxy_cache_valid 60m;
    proxy_pass http://frontend_upstream;
    # For testing cache - remove before deploying to production
    add_header X-Cache-Status $upstream_cache_status;
  }
  location / {
    proxy_pass http://frontend_upstream;
  }
  location /api {
    {{ range service "public-api" }}
      proxy_pass http://{{ .Address }}:{{ .Port }};
    {{ end }}
  }
}
        EOF
        destination = "local/default.conf"
      }
    }
  }
}
EOF
}
