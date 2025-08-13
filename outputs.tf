output "api_invoke_url" {
  description = "URL para invocar la API Gateway."
  value       = module.api_gateway.invoke_url
}

output "ec2_public_ip" {
  description = "IP Pública de la instancia EC2 para acceso SSH."
  value       = module.ec2.instance_public_ip
}

output "secret_manager_name" {
  description = "Nombre del secreto en Secrets Manager que contiene la clave SSH privada."
  value       = module.ec2.secret_name
}

output "get_private_key_command" {
  description = "Comando de AWS CLI para obtener la clave privada SSH."
  value       = module.ec2.get_secret_command
}

output "ssh_command" {
  description = "Comando para conectar a la instancia EC2 via SSH (recuerda guardar la clave primero)."
  value       = module.ec2.ssh_command
}