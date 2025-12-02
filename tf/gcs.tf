resource "google_storage_bucket" "default" {
  name                        = "${random_pet.default.id}-${data.google_project.default.number}"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "config" {
  for_each = fileset("${path.module}/../packer/configs", "*.hcl")
  bucket   = google_storage_bucket.default.name
  name     = each.key
  source   = "${path.module}/../packer/configs/${each.key}"
}

resource "google_storage_bucket_object" "license" {
  for_each = fileset("${path.module}/../", "*.hclic")
  bucket   = google_storage_bucket.default.name
  name     = each.key
  source   = "${path.module}/../${each.key}"
}