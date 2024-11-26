job "filebeat-nomad" {
  datacenters = ["dc1"]
  type        = "service"

  group "filebeat" {
    count = 1

    task "filebeat" {
      driver = "docker"

      config {
        image = "${image}"
        volumes = [
          "local/config/filebeat.yml:/usr/share/filebeat/filebeat.yml",
          "{{ gcp_key_path }}:/etc/gcp-key.json"
        ]
        env = {
          GOOGLE_APPLICATION_CREDENTIALS = "/etc/gcp-key.json"
        }
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}