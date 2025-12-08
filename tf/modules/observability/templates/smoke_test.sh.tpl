curl -v -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": {"job": "test", "source": "curl"},
        "values": [["'$(date +%s)000000000'", "Test log entry"]]
      }
    ]
  }' \
  http://gateway.traefik-dc1.${host_url_suffix}:8080/loki/api/v1/push