output "public_ip" {
  description = "IP elástica de la instancia."
  value       = aws_eip.api.public_ip
}

output "api_url" {
  description = "URL pública de la API con el dominio de No-IP."
  value       = local.api_url
}

output "front_url" {
  description = "URL pública del front servido por nginx."
  value       = local.front_url
}

output "ssh_command" {
  description = "Comando para conectarse por SSH a la instancia."
  value       = "ssh -i ${var.ssh_private_key_path} ubuntu@${aws_eip.api.public_ip}"
}

output "s3_bucket" {
  description = "Bucket S3 donde se guardan las imágenes."
  value       = aws_s3_bucket.images.bucket
}

output "docker_image" {
  description = "Imagen de la API usada por docker compose."
  value       = local.api_image
}

output "noip_hostname" {
  description = "Hostname configurado en No-IP."
  value       = var.noip_hostname
}
