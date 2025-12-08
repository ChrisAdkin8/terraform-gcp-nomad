job "minio" {
  datacenters = ["dc1"]
  type        = "service"

  group "minio-group" {
    count = 1
    
    volume "minio_data" {
      type      = "host"
      read_only = false
      source    = "minio"
    }

    network {
      port "http" {
        static = 9000
      }
      port "console" {
        static = 9090
      }
    }

    task "minio" {
      driver = "docker"

      config {
        image   = "quay.io/minio/minio:RELEASE.2024-10-02T17-50-41Z"
        command = "server"
        args    = ["--console-address", ":9090", "data1"]
        ports   = ["http", "console"]
      }

      env {
        MINIO_ROOT_USER     = "minioadmin"
        MINIO_ROOT_PASSWORD = "${minio_root_password}"
      }

      volume_mount {
        volume      = "minio_data"
        destination = "/data1"
        read_only   = false
      }

      resources {
        cpu    = 3000
        memory = 4096
      }

      service {
        name = "s3"
        port = "http"
        
        tags = [
        	"traefik.enable=true",
        	"traefik.http.routers.s3.rule=Host(`minio-s3.traefik-dc1.${gcp_project_id}.gcp.sbx.hashicorpdemo.com`)"
      	]

        check {
          type     = "http"
          path     = "/minio/health/live"
          interval = "30s"
          timeout  = "20s"
        }
      }

      service {
        name = "console"
        port = "console"
        
        tags = [
        	"traefik.enable=true",
        	"traefik.http.routers.console.rule=Host(`minio-console.traefik-dc1.hc-97b69c7c833a46a5a9144373fe3.gcp.sbx.hashicorpdemo.com`)"
      	]

        check {
          type     = "http"
          path     = "/console/health"
          interval = "30s"
          timeout  = "20s"
        }
      }
    }
  }
}