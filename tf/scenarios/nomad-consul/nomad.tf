#
# For ssh - tunnelling through IAP is required
# 
# gcloud compute ssh <instance-name> --zone=<zone> --tunnel-through-iap
#

module "secondary_nomad" {
  source = "../../modules/nomad"

  project_id             = local.project_id
  create_nomad_cluster   = var.create_secondary_nomad_cluster
  create_dns_record      = false
  datacenter             = var.secondary_datacenter
  gcs_bucket             = google_storage_bucket.default.name
  name_prefix            = local.secondary_name_prefix
  short_prefix           = random_pet.default.id
  nomad_client_instances = var.secondary_nomad_client_instances
  nomad_server_instances = var.secondary_nomad_server_instances
  region                 = var.secondary_region
  subnet_self_link       = module.network.secondary_subnet_self_link
  allowed_ingress_cidrs  = concat([local.mgmt_cidr], var.additional_allowed_cidrs)
  zone                   = data.google_compute_zones.secondary.names[0]
  base_domain            = local.base_domain
  labels                 = local.secondary_labels

  depends_on = [
    consul_acl_policy.secondary_nomad_agent,
    module.network
  ]
}

module "nomad" {
  source = "../../modules/nomad"

  project_id             = local.project_id
  create_nomad_cluster   = var.create_nomad_cluster
  create_dns_record      = true
  datacenter             = var.datacenter
  gcs_bucket             = google_storage_bucket.default.name
  name_prefix            = local.name_prefix
  short_prefix           = random_pet.default.id
  nomad_client_instances = var.nomad_client_instances
  nomad_server_instances = var.nomad_server_instances
  region                 = var.region
  subnet_self_link       = module.network.subnet_self_link
  allowed_ingress_cidrs  = concat([local.mgmt_cidr], var.additional_allowed_cidrs)
  zone                   = data.google_compute_zones.default.names[0]
  base_domain            = local.base_domain
  labels                 = local.primary_labels

  depends_on = [
    consul_acl_policy.nomad_agent,
    module.network
  ]
}

resource "random_uuid" "nomad_bootstrap" {}

resource "null_resource" "nomad_consul_setup" {
  count = var.create_nomad_cluster ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      while ! nomad server members 2>&1; do
        echo 'waiting for primary nomad cluster api...'
        sleep 10
      done

      nomad setup consul -y \
      --address=http://${module.nomad.fqdn}:4646 \
      --jwks-url=http://${module.nomad.internal_server_ips[0]}:4646/.well-known/jwks.json \
      --token=${random_uuid.nomad_bootstrap.result}
    EOF

    environment = {
      NOMAD_ADDR        = local.nomad_url
      NOMAD_TOKEN       = data.external.nomad_acl_bootstrap_token[0].result.token
      CONSUL_HTTP_ADDR  = local.consul_url
      CONSUL_HTTP_TOKEN = var.initial_management_token
    }
  }

  depends_on = [
    module.nomad,
    module.secondary_nomad,
    null_resource.nomad_acl_bootstrap,
  ]
}

resource "null_resource" "secondary_nomad_consul_setup" {
  count = var.create_secondary_nomad_cluster ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOF
      while ! nomad server members 2>&1; do
        echo 'waiting for secondary nomad cluster api...'
        sleep 10
      done

      nomad setup consul -y \
      --address=http://${module.secondary_nomad.fqdn}:4646 \
      --jwks-url=http://${module.secondary_nomad.internal_server_ips[0]}:4646/.well-known/jwks.json \
      --token=${random_uuid.nomad_bootstrap.result}
    EOF

    environment = {
      NOMAD_ADDR        = local.secondary_nomad_url
      NOMAD_TOKEN       = data.external.secondary_nomad_acl_bootstrap_token[0].result.token
      CONSUL_HTTP_ADDR  = local.secondary_consul_url
      CONSUL_HTTP_TOKEN = var.initial_management_token
    }
  }

  depends_on = [
    module.nomad,
    module.secondary_nomad,
    null_resource.nomad_consul_setup,
    null_resource.secondary_nomad_acl_bootstrap,
  ]
}

#
# Nomad ACL Bootstrap
#
# This bootstraps the Nomad ACL system and captures the management token.
# The token is stored in a local file and made available as a Terraform output.
#

resource "null_resource" "nomad_acl_bootstrap" {
  count = var.create_nomad_cluster ? 1 : 0

  triggers = {
    nomad_servers = join(",", module.nomad.external_server_ips)
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -e

      # Wait for Nomad API to be available
      echo "Waiting for Nomad API to be available..."
      for i in $(seq 1 60); do
        if curl -sf "${local.nomad_url}/v1/status/leader" > /dev/null 2>&1; then
          echo "Nomad API is available"
          break
        fi
        echo "Attempt $i/60: Waiting for Nomad API..."
        sleep 10
      done

      # Bootstrap ACLs and capture the token
      echo "Bootstrapping Nomad ACLs..."
      BOOTSTRAP_OUTPUT=$(nomad acl bootstrap -json 2>&1) || {
        # Check if already bootstrapped
        if echo "$BOOTSTRAP_OUTPUT" | grep -q "bootstrap already performed"; then
          echo "ACLs already bootstrapped. Token file may exist from previous run."
          exit 0
        fi
        echo "Bootstrap failed: $BOOTSTRAP_OUTPUT"
        exit 1
      }

      # Extract and save the SecretID
      TOKEN=$(echo "$BOOTSTRAP_OUTPUT" | jq -r '.SecretID')
      if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
        echo "$TOKEN" > "${path.module}/nomad_acl_bootstrap_token.txt"
        chmod 600 "${path.module}/nomad_acl_bootstrap_token.txt"
        echo "Nomad ACL bootstrap token saved to ${path.module}/nomad_acl_bootstrap_token.txt"
      else
        echo "Failed to extract bootstrap token from output"
        exit 1
      fi
    EOF

    environment = {
      NOMAD_ADDR = local.nomad_url
    }
  }

  depends_on = [
    module.nomad,
  ]
}

resource "null_resource" "secondary_nomad_acl_bootstrap" {
  count = var.create_secondary_nomad_cluster ? 1 : 0

  triggers = {
    nomad_servers = join(",", module.secondary_nomad.external_server_ips)
  }

  provisioner "local-exec" {
    command = <<-EOF
      set -e

      # Wait for Nomad API to be available
      echo "Waiting for Secondary Nomad API to be available..."
      for i in $(seq 1 60); do
        if curl -sf "${local.secondary_nomad_url}/v1/status/leader" > /dev/null 2>&1; then
          echo "Secondary Nomad API is available"
          break
        fi
        echo "Attempt $i/60: Waiting for Secondary Nomad API..."
        sleep 10
      done

      # Bootstrap ACLs and capture the token
      echo "Bootstrapping Secondary Nomad ACLs..."
      BOOTSTRAP_OUTPUT=$(nomad acl bootstrap -json 2>&1) || {
        # Check if already bootstrapped
        if echo "$BOOTSTRAP_OUTPUT" | grep -q "bootstrap already performed"; then
          echo "ACLs already bootstrapped. Token file may exist from previous run."
          exit 0
        fi
        echo "Bootstrap failed: $BOOTSTRAP_OUTPUT"
        exit 1
      }

      # Extract and save the SecretID
      TOKEN=$(echo "$BOOTSTRAP_OUTPUT" | jq -r '.SecretID')
      if [ -n "$TOKEN" ] && [ "$TOKEN" != "null" ]; then
        echo "$TOKEN" > "${path.module}/nomad_acl_bootstrap_token_secondary.txt"
        chmod 600 "${path.module}/nomad_acl_bootstrap_token_secondary.txt"
        echo "Secondary Nomad ACL bootstrap token saved to ${path.module}/nomad_acl_bootstrap_token_secondary.txt"
      else
        echo "Failed to extract bootstrap token from output"
        exit 1
      fi
    EOF

    environment = {
      NOMAD_ADDR = local.secondary_nomad_url
    }
  }

  depends_on = [
    module.secondary_nomad,
    null_resource.nomad_acl_bootstrap,
  ]
}

# Read the bootstrap token from file after bootstrap completes
data "external" "nomad_acl_bootstrap_token" {
  count = var.create_nomad_cluster ? 1 : 0

  program = ["bash", "-c", <<-EOF
    TOKEN_FILE="${path.module}/nomad_acl_bootstrap_token.txt"
    if [ -f "$TOKEN_FILE" ]; then
      TOKEN=$(cat "$TOKEN_FILE")
      echo "{\"token\": \"$TOKEN\"}"
    else
      echo "{\"token\": \"\"}"
    fi
  EOF
  ]

  depends_on = [null_resource.nomad_acl_bootstrap]
}

data "external" "secondary_nomad_acl_bootstrap_token" {
  count = var.create_secondary_nomad_cluster ? 1 : 0

  program = ["bash", "-c", <<-EOF
    TOKEN_FILE="${path.module}/nomad_acl_bootstrap_token_secondary.txt"
    if [ -f "$TOKEN_FILE" ]; then
      TOKEN=$(cat "$TOKEN_FILE")
      echo "{\"token\": \"$TOKEN\"}"
    else
      echo "{\"token\": \"\"}"
    fi
  EOF
  ]

  depends_on = [null_resource.secondary_nomad_acl_bootstrap]
}