gcloud auth application-default login
sleep 3
gcloud auth login

PROJECT_ID=$(gcloud config get-value project)

# Update terraform.tfvars with the Project ID
echo "project_id="\"$PROJECT_ID\" > tf/terraform.tfvars

# Default region to London
gcp_region="europe-west2"

# Default zone to London
gcp_zone="europe-west2-a"

# Default value for image_family
image_family="almalinux-8"

# Create or overwrite the .pkrvars.hcl file with the provided values
cat <<EOF > packer/variables.pkrvars.hcl
gcp_project_id = "$PROJECT_ID"
gcp_region     = "${gcp_region}"
gcp_zone       = "${gcp_zone}"
image_family   = "${image_family}"
EOF

# Print success message
echo "Variables saved to variables.pkrvars.hcl:"
cat packer/variables.pkrvars.hcl
