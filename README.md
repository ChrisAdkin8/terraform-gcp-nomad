# Nomad and Consul Setup on GCP

This guide outlines how to deploy **Nomad** and **Consul** on **Google Cloud Platform (GCP)** using **Packer** to build custom images based on HashiCorp's [Reference Architecture](https://developer.hashicorp.com/nomad/tutorials/enterprise/production-reference-architecture-vm-with-consul).

![Reference Diagram](./docs/reference-diagram.png)

## Prerequisites

Before you begin, ensure you have the following tools installed:

- [Google Cloud CLI (gcloud)](https://cloud.google.com/sdk/docs/install)
- [HashiCorp Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli)
- [HashiCorp Terraform](https://developer.hashicorp.com/terraform/install)
- [Task](https://taskfile.dev/installation/)
- **Nomad License File**
- **Consul License File**

## Step 1: Authenticate with GCP

Invoke the following script:
```bash
./project.sh
```
The script:
- Authenticates you for Google Cloud SDK and tools
- Authenticates your application with Application Default Credentials (ADC)
- Adds the GCP Project Id to the `packer/variables.pkr.hcl` file
- Refreshes the `tf/terraform.tfvars` file with the GCP Project Id

Note:

- The current project can be obtained using:
`gcloud config get-value project`

- The current project can be set using:
`gcloud config set project`

## Step 2: Set Up License Files

Copy your **Nomad** and **Consul** license files (`nomad.hclic` and `consul.hclic`) to the root of your working directory:

```bash
cp ~/Downloads/nomad.hclic .
cp ~/Downloads/consul.hclic .
```

Ensure both license files are present before building your images.

## Step 3: Build Disk Images with Packer

### Go Task Method
```
task packer
```

### Manual Method

#### Build the Images

Once variables are set, you can use **Packer** to build the **Nomad** server and client images. To update the version of **Nomad** or **Consul**, modify the `NOMAD_VERSION` and `CONSUL_VERSION` in the [provision-nomad.sh](./packer/scripts/provision-nomad.sh) & [provision-consul.sh](./packer/scripts/provision-consul.sh) scripts.

Alternatively, you can run both builds simultaneously using `./build-packer.sh`, or manually with the following commands:

```bash
# Initialize Packer
packer init packer/gcp-almalinux-nomad-server.pkr.hcl
packer init packer/gcp-almalinux-nomad-client.pkr.hcl
packer init packer/gcp-almalinux-consul-server.pkr.hcl

# Build the Nomad server image
packer build -var-file=variables.pkrvars.hcl packer/gcp-almalinux-nomad-server.pkr.hcl

# Build the Nomad client image
packer build -var-file=variables.pkrvars.hcl packer/gcp-almalinux-nomad-client.pkr.hcl

# Build the Consul server image
packer build -var-file=variables.pkrvars.hcl packer/gcp-almalinux-consul-server.pkr.hcl
```

## Step 4: Provision Nomad Cluster with Terraform

### Go Task Method
```
task apply
```

### Manual Method

You can now use Terraform to provision a **Nomad** cluster. This example creates a 3-node Nomad server cluster with an additional Nomad client node. The `terraform.tfvars` file is generated from the original `variables.pkrvars.hcl` used during the Packer build.

```bash
# Create tfvars from pkrvars and provision the cluster
sed '/image_family.*/d' variables.pkrvars.hcl > tf/terraform.tfvars
cd tf
terraform init
terraform apply
```

## Firewall Configuration
The firewall rule will open TCP ports 4646 and 8500, allowing you to access Nomad on port 4646 and Consul on port 8500 on the relevent the servers. You can access these services via a web browser using the external IP addresses of your servers. 

# Kubernetes Integration (Work in Progress)

Integration with **Kubernetes** is currently a work in progress. Stay tuned for updates on how to incorporate **Nomad** into your Kubernetes environment.
