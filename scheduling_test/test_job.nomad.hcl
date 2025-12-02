job "duration-test" {
  datacenters = ["dc1"]
  type        = "batch" # Critical: Ensures the job runs to completion and doesn't restart

  parameterized {
    payload = "optional"
    meta_required = ["DISPATCH_ID"] # Ensures a unique ID is passed on dispatch
  }

  group "test" {
    task "latency" {
      driver = "docker"

      config {
        image = "alpine:3"
        # The command runs for 1 second, simulating a workload.
        # It uses the passed DISPATCH_ID just to prove uniqueness.
        command = "sh"
        args = ["-c", "echo Dispatch ID: ${NOMAD_META_DISPATCH_ID}; sleep 1"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}
