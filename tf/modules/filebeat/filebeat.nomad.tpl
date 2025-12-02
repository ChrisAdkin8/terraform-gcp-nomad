job "filebeat-nomad" {
  datacenters = ["dc1"]
  type        = "service"

  group "filebeat" {
    count = 1

    task "logstash" {
      driver = "docker"

      template {
        data = <<EOF
        input {
          beats {
            port => 5044
          }
        }

        output {
          stdout { codec => json }
          http {
            url => "https://logging.googleapis.com/v2/entries:write"
            http_method => "post"
            headers => {
              "Authorization" => "Bearer {{ env "GOOGLE_APPLICATION_CREDENTIALS" }}"
            }
            format => "json"
            content_type => "application/json"
            message => '{
              "logName": "projects/${project_id}/logs/YOUR_LOG_NAME",
              "resource": { "type": "global" },
              "entries": [
                { "jsonPayload": %%%{[event]} }
              ]
            }'
          }
        }
        EOF
        destination = "local/logstash.conf"
      }

      template {
        data = <<EOF
        xpack.monitoring.enabled: false
        xpack.license.self_managed: true
        EOF
        destination = "local/logstash.yml"
      }

      config {
        image = "docker.elastic.co/logstash/logstash:8.16.1"
        volumes = [
          "local/logstash.conf:/usr/share/logstash/pipeline/logstash.conf",
          "local/logstash.yml:/usr/share/logstash/config/logstash.yml",
          "{{ gcp_key_path }}:/etc/gcp-key.json"
        ]
      }

      env = {
        GOOGLE_APPLICATION_CREDENTIALS = "/etc/gcp-key.json"
      }

      resources {
        cpu    = 500
        memory = 2048
      }
    }

    task "filebeat" {
      driver = "docker"

      template {
        data = <<EOF
        filebeat.inputs:
          - type: httpjson
            enabled: true
            config:
              # Fetch allocation details from Nomad
              urls:
                - "http://{{ env "NOMAD_ADDR" }}/v1/allocation/{{ env "NOMAD_ALLOC_ID" }}"
              interval: 10s
              request:
                method: GET
                headers:
                  Content-Type: application/json
                body: ""
                content_type: application/json
              response:
                split:
                  target: "allocations"
                  field: ""

              # Add Nomad metadata
              processors:
                - add_fields:
                    target: ""
                    fields:
                      nomad_alloc_id: "{{ env "NOMAD_ALLOC_ID" }}"
                      nomad_job_id: "{{ env "NOMAD_JOB_ID" }}"
                      nomad_client_status: "{{ env "NOMAD_CLIENT_STATUS" }}"
                      nomad_desired_status: "{{ env "NOMAD_DESIRED_STATUS" }}"

        output.logstash:
          hosts: ["localhost:5044"]
          content_type: "application/json"

          body: >
            {
              "logName": "projects/${project_id}/logs/nomad-allocation-logs",
              "resource": {
                "type": "global"
              },              
              "entries": [
                {
                  "jsonPayload": {
                    "allocation_id": "{{ env "NOMAD_ALLOC_ID" }}",
                    "job_id": "{{ env "NOMAD_JOB_ID" }}",
                    "client_status": "{{ env "NOMAD_CLIENT_STATUS" }}",
                    "desired_status": "{{ env "NOMAD_DESIRED_STATUS" }}"
                  }
                }
              ]
            }
        EOF
        destination = "local/filebeat.yml"
      }

      config {
        image = "elastic/filebeat:8.16.1"
        volumes = [
          "local/filebeat.yml:/usr/share/filebeat/filebeat.yml",
          "{{ gcp_key_path }}:/etc/gcp-key.json"
        ]
      }
      
      env = {
        GOOGLE_APPLICATION_CREDENTIALS = "/etc/gcp-key.json"
        NOMAD_ADDR = "http://nomad-dc1.hc-feb7b4ef5b7c4bf7afa2126b6d2.gcp.sbx.hashicorpdemo.com:4646"
      }

      resources {
        cpu    = 500
        memory = 256 
      }
    }
  }
}