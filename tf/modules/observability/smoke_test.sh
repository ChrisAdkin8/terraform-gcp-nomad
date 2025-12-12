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
  http://gateway.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com.gcp.sbx.hashicorpdemo.com:8080/loki/api/v1/push
sleep 2
curl -v -G \
  --data-urlencode 'query={job="test", source="curl"}' \
  http://loki.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com.gcp.sbx.hashicorpdemo.com:8080/loki/api/v1/query   