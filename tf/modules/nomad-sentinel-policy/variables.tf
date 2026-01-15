variable "nomad_address" {
  type        = string
  description = "Nomad cluster API address"
}


variable "allowed_artifact_prefixes" {
  description = "List of allowed artifact source prefixes"
  type        = list(string)
  default = [
    "https://artifacts.company.com/",
    "s3::https://company-bucket.s3.amazonaws.com/approved/",
  ]
}
