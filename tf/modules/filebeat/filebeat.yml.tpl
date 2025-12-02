filebeat.inputs:
  - type: httpjson
    enabled: true
    config:
      # Fetch allocation details from Nomad
      urls:
        - "${nomad_addr}/v1/allocations"
      interval: 10s
      request.method: GET
      response:
        split:
          target: "allocations"
          field: ""

      # Enrich allocation data with job information
      processors:
        # Add Nomad allocation metadata
        - add_fields:
            target: ""
            fields:
              nomad_alloc_id: "{{ allocations.ID }}"
              nomad_job_id: "{{ allocations.JobID }}"
              nomad_node_id: "{{ allocations.NodeID }}"
              nomad_client_status: "{{ allocations.ClientStatus }}"
              nomad_desired_status: "{{ allocations.DesiredStatus }}"

        # Query Nomad for job details and enrich logs
        - httpjson:
            config:
              urls:
                - "${nomad_addr}/v1/job/{{ allocations.JobID }}"
              request.method: GET
              response:
                split:
                  target: "job"
                  field: ""

        # Add job-specific fields
        - add_fields:
            target: ""
            fields:
              nomad_job_name: "{{ job.Name }}"
              nomad_team_owner: "{{ job.Meta.team_owner }}" # Assuming 'team_owner' is a custom meta field

        # Query Nomad task logs for each allocation
        - httpjson:
            config:
              urls:
                - "${nomad_addr}/v1/client/allocation/{{ allocations.ID }}/logs?task={{ allocations.Name }}&type=stdout"
              request.method: GET
              response:
                split:
                  target: "logs"
                  field: ""

        # Optional: Filter out allocations not meeting certain conditions
        - drop_event:
            when:
              not:
                equals:
                  nomad_client_status: "running"

output.http:
  enabled: true
  hosts: ["https://logging.googleapis.com"]
  headers:
    Authorization: "Bearer $${GOOGLE_APPLICATION_CREDENTIALS}"
  path: "/v2/entries:write"
  method: POST
  content_type: "application/json"

  # Map enriched fields into a Google Cloud Logging entry
  body: >
    {
      "logName": "projects/${project_id}/logs/nomad-allocation-logs",
      "resource": {
        "type": "global"
      },
      "entries": [
        {
          "jsonPayload": {
            "allocation_id": "{{ nomad_alloc_id }}",
            "job_id": "{{ nomad_job_id }}",
            "job_name": "{{ nomad_job_name }}",
            "team_owner": "{{ nomad_team_owner }}",
            "node_id": "{{ nomad_node_id }}",
            "client_status": "{{ nomad_client_status }}",
            "desired_status": "{{ nomad_desired_status }}",
            "log": "{{ logs.stdout }}"
          }
        }
      ]
    }
