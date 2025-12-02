nomad alloc exec -task alloy 1da242c1 curl -X POST "http://gateway.traefik-dc1.hc-876c7e1f6c624bf4819941f43be.gcp.sbx.hashicorpdemo.com:8080/loki/api/v1/push" \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": { "job": "test" },
        "values": [
          [ "'$(date +%s)000000000'", "test log message" ]
        ]
      }
    ]
  }'
