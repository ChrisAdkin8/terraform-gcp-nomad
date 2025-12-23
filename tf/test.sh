curl -sf "${NOMAD_ADDR}/v1/node/${NODE_ID}/allocations" | jq '[.[] | select(.ClientStatus == "running") |
  {
    targets: ["/opt/nomad/data/alloc/\(.ID)/alloc/logs/*.stdout.[0-9]*"],
    labels: {
      job: .JobID,
      namespace: .Namespace,
      task_group: .TaskGroup,
      alloc_id: .ID,
      stream: "stdout"
    }
  },
  {
    targets: ["/opt/nomad/data/alloc/\(.ID)/alloc/logs/*.stderr.[0-9]*"],
    labels: {
      job: .JobID,
      namespace: .Namespace,
      task_group: .TaskGroup,
      alloc_id: .ID,
      stream: "stderr"
    }
  }
]'
