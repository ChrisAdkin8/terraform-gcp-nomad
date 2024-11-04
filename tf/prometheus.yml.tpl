global:
  scrape_interval: 15s  # Set the global scrape interval to 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s  # Evaluate rules every 15 seconds. The default is every 1 minute.

scrape_configs:
  - job_name: 'nomad'
    metrics_path: '/v1/metrics'
    scrape_interval: 15s
    static_configs:
      - targets: [ ${metrics_endpoint}]  