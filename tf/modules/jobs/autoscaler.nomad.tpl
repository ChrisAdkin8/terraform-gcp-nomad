job "nomad_autoscaler" {

  region      = "global"
  datacenters = ["dc1"]
  namespace   = "default"

  group "autoscaler" {

    network {
      port "http" {
        to = 8080
      }
    }

    task "autoscaler_agent" {
      driver = "docker"

      config {
        image   = "hashicorp/nomad-autoscaler:0.3.3"
        command = "nomad-autoscaler"
        ports   = [ "http" ]
        args    = [
  "agent",
  "-nomad-address=${nomad_address}",
  "-http-bind-address=0.0.0.0"
]
      }

      resources {
        cpu    = 500
        memory = 256
      }
      service {
        name = "nomad-autoscaler"
        port = "http"
        tags = []

        check {
          type     = "http"
          path     = "/v1/health"
          interval = "3s"
          timeout  = "1s"
        }
      }
    }
  }
}