curl -sf "${NOMAD_ADDR}/v1/node/${NODE_ID}/allocations" | jq '[.[] | select(.ClientStatus == "running")
