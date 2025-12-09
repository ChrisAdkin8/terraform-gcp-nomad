job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "system"
  
  group "traefik" {
    count = 1
    
    network {
      port "http" {
        static = 8080
      }
      port "api" {
        static = 8081
      }
      port "otlp" {
        static = 4317
      }
    }
    
    service {
      name = "traefik"
      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "30s"
        timeout  = "5s"
      }
    }
    
    task "traefik" {
      driver = "docker"
      
      config {
        image        = "traefik:v3.6.2"
        network_mode = "host"
        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }
      
      template {
        data = <<EOF
[global]
    checkNewVersion = false
    sendAnonymousUsage = false

[entryPoints]    
    [entryPoints.otlp-grpc]
    address = ":4317"
    [entryPoints.otlp-grpc.transport]
        [entryPoints.otlp-grpc.transport.respondingTimeouts]
            readTimeout = "60s"
            writeTimeout = "60s"
            idleTimeout = "180s"
    
    [entryPoints.http]
    address = ":8080"
    [entryPoints.http.transport]
        [entryPoints.http.transport.respondingTimeouts]
            readTimeout = "60s"
            writeTimeout = "60s"
            idleTimeout = "180s"
    
    [entryPoints.traefik]
    address = ":8081"

[api]
    dashboard = true
    insecure  = true

[log]
    level  = "DEBUG"
    format = "common"

[accessLog]
    format = "json"
    [accessLog.fields]
        defaultMode = "keep"
        [accessLog.fields.headers]
            defaultMode = "keep"

[serversTransport]
    maxIdleConnsPerHost = 200

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false
    refreshInterval  = "15s"
    [providers.consulCatalog.endpoint]
      address = "{{ env "attr.unique.network.ip-address" }}:8500"
      scheme  = "http"
      token   = "{{ with nomadVar "nomad/jobs/traefik" }}{{ .consul_token }}{{ end }}"
EOF
        destination = "local/traefik.toml"
      }
      
      resources {
        cpu    = 1000
        memory = 768
      }
    }
  }
}