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

Authenticate your GCP account and configure the project you want to use:

```bash
# Authenticate your GCP account with application-default
gcloud auth application-default login

# Authenticate your GCP account with application-default
gcloud auth login

# Set your Google Cloud project ID
gcloud config set project <PROJECT_ID>
```

Replace `<PROJECT_ID>` with your GCP project ID.

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

#### Set Packer Variables

Use the provided script to configure necessary variables for the Packer build:

```bash
sh packer/set-vars.sh
```

The script will prompt you for your GCP project ID, region, and other details. By default, it uses **London (europe-west2)** as the region. Modify this if needed during execution.

#### Build the Images

Once variables are set, you can use **Packer** to build the **Nomad** server and client images. To update the version of **Nomad** or **Consul**, modify the `NOMAD_VERSION` and `CONSUL_VERSION` in the [provision-nomad.sh](./packer/scripts/provision-nomad.sh) & [provision-consul.sh](./packer/scripts/provision-consul.sh) scripts.

The fastest way to do this is to issue the following command:
```bash
task packer
```

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

You can now use Terraform to provision a **Nomad** cluster. This example creates a 3-node Nomad server cluster with an additional Nomad client node. The `terraform.tfvars` file is generated from the original `variables.pkrvars.hcl` used during the Packer build.

The fastest way to do this is to issue the following command:
```bash
task apply
```
Otherwise, this can be performed by using the following commands:

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
