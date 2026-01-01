job "loki" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert      = true
  }

  group "loki" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "5m"
      mode     = "fail"
    }
    
    network {      
      port "http" {
        static = 3100
      }
      port "grpc" {
        static = 9096
      }
    }
    
    volume "loki_data" {
      type            = "host"
      source          = "loki"
      access_mode     = "single-node-single-writer"
      attachment_mode = "file-system"
    }
    
    task "loki" {
      driver = "docker"
      user   = "root"
      
      config {
        image = "grafana/loki:2.9.3"
        ports = ["http", "grpc"]
        args  = ["-config.file=/local/loki-config.yaml"]
      }
      
      volume_mount {
        volume      = "loki_data"
        destination = "/loki"
      }

      template {
        data = <<EOF
{{ with nomadVar "nomad/jobs/loki/loki_group/loki" }}{{ .gcs_service_account_key }}{{ end }}
EOF
        destination = "secrets/gcs-key.json"
        change_mode = "restart"
      }
      
      template {
        data = <<EOF
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096
  grpc_server_max_recv_msg_size: 8388608
  grpc_server_max_send_msg_size: 8388608
  http_server_read_timeout: 600s
  http_server_write_timeout: 600s
  log_level: warn

common:
  path_prefix: /loki
  storage:
    gcs:
      bucket_name: {{ with nomadVar "nomad/jobs/loki/loki_group/loki" }}{{ .gcs_bucket_name }}{{ end }}
      chunk_buffer_size: 104857600
      request_timeout: 0s
      enable_http2: true
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb           
      object_store: gcs
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  query_timeout: 5m 
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 32
  ingestion_burst_size_mb: 64
  max_query_parallelism: 32
  max_streams_per_user: 10000
  max_global_streams_per_user: 10000
  max_query_length: 721h
  max_query_lookback: 168h
  max_entries_limit_per_query: 5000
  max_cache_freshness_per_query: 10m
  split_queries_by_interval: 30m

chunk_store_config:
  max_look_back_period: 0s
  chunk_cache_config:
    embedded_cache:
      enabled: true
      max_size_mb: 1024
      ttl: 1h

query_range:
  align_queries_with_step: true
  cache_results: true
  max_retries: 5
  parallelise_shardable_queries: true
  results_cache:
    cache:
      embedded_cache:
        enabled: true
        max_size_mb: 512
        ttl: 24h

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h

compactor:
  working_directory: /loki/compactor
  shared_store: gcs
  compaction_interval: 10m
  retention_enabled: true
  retention_delete_delay: 2h
  retention_delete_worker_count: 150
EOF
        destination = "local/loki-config.yaml"
        change_mode = "restart"
      }
      
      resources {
        cpu    = 1000
        memory = 4096
      }
      
      service {
        name = "loki"
        port = "http"
        
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.loki.rule=Host(`loki.${host_url_suffix}`)",
          "traefik.http.routers.loki.entrypoints=http",
          "traefik.http.services.loki.loadbalancer.server.port=3100"
        ]
        
        check {
          type     = "http"
          path     = "/ready"
          interval = "10s"
          timeout  = "5s"
        }
      }
    }
  }
}