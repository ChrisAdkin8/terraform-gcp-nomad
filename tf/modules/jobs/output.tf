output "minio_root_password" {
    value = random_password.password.result
}