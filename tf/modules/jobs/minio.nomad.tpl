job "minio" {
  datacenters = ["dc1"]
  type        = "service"

  group "minio-group" {
    count = 1
    
    volume "minio_data" {
      type      = "host"
      read_only = false
      source    = "hv001"
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
        image   = "quay.io/minio/minio:latest"
        command = "server"
        args    = ["--console-address", ":9090", "data1"]
        ports   = ["http", "console"]
      }

      env {
        MINIO_ROOT_USER     = "minioadmin"
        MINIO_ROOT_PASSWORD = "minioadmin"
      }

      volume_mount {
        volume      = "minio_data"
        destination = "/data1"
        read_only   = false
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 512 # 512MB
      }

      service {
        name = "s3"
        port = "http"
        
        tags = [
        	"traefik.enable=true",
        	"traefik.http.routers.s3.rule=Path(`/s3`)",
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
        	"traefik.http.routers.console.rule=Path(`/console`)",
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