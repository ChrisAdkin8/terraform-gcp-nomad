# The Grafana Based Observability Stack

## High Level Architecture

```mermaid
flowchart TB
    subgraph Internet
        users([Users / Clients])
    end

    subgraph GCP["Google Cloud Platform"]
        lb[["GCP Load Balancer"]]
        
        subgraph nomad["Nomad Cluster"]
            subgraph ingress["Ingress Layer"]
                traefik["Traefik (Reverse Proxy)"]
            end
            
            subgraph observability["Observability Stack"]
                grafana["Grafana (Dashboards)"]
                loki["Loki (Log Aggregation)"]
                
                subgraph alloy_stack["Alloy"]
                    alloy_gw["Alloy Gateway (Receiver)"]
                    alloy_collectors["Alloy Collectors (Agents)"]
                end
            end
        end
        
        subgraph consul_cluster["Service Mesh"]
            consul[("Consul (Service Catalog)")]
        end
        
        subgraph storage["Storage"]
            gcs[("GCS Bucket (Loki Chunks)")]
        end
    end

    %% Traffic flow
    users --> lb
    lb --> traefik
    
    %% Traefik routing to services
    traefik --> grafana
    traefik --> loki
    traefik --> alloy_gw
    
    %% Consul service discovery
    consul <-.->|service discovery| traefik
    consul <-.->|register| grafana
    consul <-.->|register| loki
    consul <-.->|register| alloy_gw
    
    %% Alloy data flow
    alloy_collectors -->|push logs| alloy_gw
    alloy_gw -->|forward| loki
    
    %% Loki storage
    loki -->|store/query| gcs
    
    %% Grafana queries
    grafana -.->|query| loki

    %% Styling
    classDef gcp fill:#4285f4,stroke:#1a73e8,color:#fff
    classDef nomad fill:#00ca8e,stroke:#00a876,color:#fff
    classDef consul fill:#dc477d,stroke:#b93366,color:#fff
    classDef storage fill:#f9ab00,stroke:#e69500,color:#000
    classDef traefik fill:#24a1c1,stroke:#1d8aa8,color:#fff
    classDef observability fill:#ff6b35,stroke:#e55a2b,color:#fff
    
    class lb gcp
    class traefik traefik
    class consul consul
    class gcs storage
    class grafana,loki,alloy_gw,alloy_collectors observability
```

## Collector Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Each Nomad Node (system job)                                                │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │ alloy-collector                                                      │   │
│  │                                                                      │   │
│  │  ┌──────────────────┐     ┌─────────────────────┐                    │   │
│  │  │ discovery.nomad  │────►│ discovery.relabel   │                    │   │
│  │  │ (service disco)  │     │ (stdout + stderr)   │                    │   │
│  │  └──────────────────┘     │                     │                    │   │
│  │                           │ Labels:             │                    │   │
│  │                           │ • job               │                    │   │
│  │                           │ • namespace         │                    │   │
│  │                           │ • task_group        │──┐                 │   │
│  │                           │ • task              │  │                 │   │
│  │                           │ • alloc_id          │  │                 │   │
│  │                           │ • stream            │  │                 │   │
│  │                           └─────────────────────┘  │                 │   │
│  │                                                    ▼                 │   │
│  │  ┌──────────────────┐     ┌─────────────────────────────────┐        │   │
│  │  │ local.file_match │────►│ loki.source.file                │        │   │
│  │  │ (fallback glob)  │     │         │                       │        │   │
│  │  └──────────────────┘     │         ▼                       │        │   │
│  │                           │ loki.process (add node label)   │        │   │
│  │                           │         │                       │        │   │
│  │  ┌──────────────────┐     │         ▼                       │        │   │
│  │  │ local.file_match │────►│ loki.write.gateway ─────────────┼────────┼───┼──►
│  │  │ (system logs)    │     └─────────────────────────────────┘        │   │
│  │  └──────────────────┘                                                │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                                                              │
                                                                              ▼
                                                              ┌───────────────────────┐
                                                              │       Gateway         │
                                                              │                       │
                                                              │  loki.source.api      │
                                                              │        │              │
                                                              │        ▼              │
                                                              │  loki.write ──────────┼──► Loki
                                                              └───────────────────────┘
```

## Performing A Basic Smoke Test

### Step 1: Submit a simple payload to the Gateway Loki endpoint:

```
curl -X POST \
  -H "Content-Type: application/json" \
  "http://gateway-api.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com:8080/loki/api/v1/push" \
  -d '{
    "streams": [{
      "stream": { "job": "test", "source": "curl" },
      "values": [[ "'$(date +%s)000000000'", "Test log message" ]]
    }]
  }'
```

Once the lab environment has been built, the gateway Loki endpoint is visible from ```terraform output```

### Step 2: Query the Loki endpoint to ensxure that the test pauload has made its way from the gateway to Loki

```
curl -v -G \  
  --data-urlencode 'query={job="test", source="curl"}' \
  http://loki.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com:8080/loki/api/v1/query
```

If the simple test has been successful, the output from this command should like similar to this, the contents of the result array is all important here:

```
  http://loki.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com:8080/loki/api/v1/query          
* Host loki.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com:8080 was resolved.
* IPv6: (none)
* IPv4: 35.206.181.151
*   Trying 35.206.181.151:8080...
* Connected to loki.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com (35.206.181.151) port 8080
> GET /loki/api/v1/query?query=%7bjob%3d%22test%22%2c+source%3d%22curl%22%7d HTTP/1.1
> Host: loki.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com:8080
> User-Agent: curl/8.7.1
> Accept: */*
> 
* Request completely sent off
< HTTP/1.1 200 OK
< content-length: 1709
< content-type: application/json; charset=utf-8
< date: Fri, 12 Dec 2025 20:06:09 GMT
< results-cache-gen-number: 
< via: 1.1 google
< 
{"status":"success","data":{"resultType":"streams","result":[{"stream":{"job":"test","source":"curl"},"values":[["1765569953149339232","Test log message"]]}],"stats":{"summary":{"bytesProcessedPerSecond":17115,"linesProcessedPerSecond":1069,"totalBytesProcessed":16,"totalLinesProcessed":1,"execTime":0.000935,"queueTime":0.000106,"subqueries":0,"totalEntriesReturned":1,"splits":0,"shards":0,"totalPostFilterLines":1,"totalStructuredMetadataBytesProcessed":0},"querier":{"store":{"totalChunksRef":0,"totalChunksDownloaded":0,"chunksDownloadTime":0,"chunk":{"headChunkBytes":0,"headChunkLines":0,"decompressedBytes":0,"decompressedLines":0,"compressedBytes":0,"totalDuplicates":0,"postFilterLines":0,"headChunkStructuredMetadataBytes":0,"decompressedStructuredMetadataBytes":0}}},"ingester":{"totalReached":1,"totalChunksMatched":1,"totalBatches":2,"totalLinesSent":1,"store":{"totalChunksRef":0,"totalChunksDownloaded":0,"chunksDownloadTime":0,"chunk":{"headChunkBytes":16,"headChunkLines":1,"decompressedBytes":0,"decompressedLines":0,"compressedBytes":0,"totalDuplicates":0,"postFilterLines":1,"headChunkStructuredMetadataBytes":0,"decompressedStructuredMetadataBytes":0}}},"cache":{"chunk":{"entriesFound":0,"entriesRequested":0,"entriesStored":0,"bytesReceived":0,"bytesSent":0,"requests":0,"downloadTime":0},"index":{"entriesFound":0,"entriesRequested":0,"entriesStored":0,"bytesReceived":0,"bytesSent":0,"requests":0,"downloadTime":0},"result":{"entriesFound":0,"entriesRequested":0,"entriesStored":0,"bytesReceived":0,"bytesSent":0,"requests":0,"downloadTime":0},"statsResult":{"entriesFound":0,"entriesRequested":0,"entriesStored":0,"bytesReceived":0,"bytesSent":0,"requests":0,"downloadTime":0}}}}}
* Connection #0 to host loki.traefik-dc1.hc-46d118b4f2d846539719e6879b9.gcp.sbx.hashicorpdemo.com left intact
```

**Important: Understanding Loki's Write Behavior**

Loki does **not** write to GCS immediately. Data is batched in memory before being flushed to object storage. Test entries won't appear in the bucket until:

- The chunk fills up (based on size/time thresholds)
- A flush is manually triggered
- Loki restarts


### Step 3: Force a Flush to GCS

```bash
# Trigger flush via Loki's API
curl -X POST "$LOKI_URL/flush"

# Alternative: restart the Loki task (Nomad)
nomad alloc restart -task loki <alloc-id>
```

Wait 10-30 seconds for the flush to complete.

### Step 4: Inspect the GCS Bucket

### List Bucket Contents

```bash
# List all contents
gsutil ls -la gs://<YOUR_BUCKET_NAME>/

# Recursive listing
gsutil ls -r gs://<YOUR_BUCKET_NAME>/

# Look for chunks and index files specifically
gsutil ls -la gs://<YOUR_BUCKET_NAME>/fake/
gsutil ls -la gs://<YOUR_BUCKET_NAME>/index/
```

### Expected Directory Structure

After Loki flushes data, you should see something like:

```
gs://<bucket>/
├── fake/                     # Chunk data (tenant folder)
│   └── <tenant-id>/
│       └── *.gz
├── index/                    # TSDB index files
│   └── index_<date>/
│       └── compactor-*.tsdb.gz
└── loki/
    └── compactor/
```

### Understanding GCS Contents

The data in GCS is **not** human-readable. Loki stores compressed chunks and TSDB index files:

```bash
# Download a chunk to inspect (it's binary/compressed)
gsutil cp gs://<bucket>/fake/<tenant>/chunks/<chunk-file> ./chunk.gz
file ./chunk.gz  # Will show it's gzip compressed
```

You cannot read the raw log content directly from GCS—it's in Loki's internal format.

