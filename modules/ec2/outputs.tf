output "instance_id" {
  value = aws_instance.app_server.id
}

output "instance_public_ip" {
  value = aws_instance.app_server.public_ip
}

output "secret_name" {
  value = aws_secretsmanager_secret.private_key_secret.name
}

output "get_secret_command" {
  value = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.private_key_secret.name} --query SecretString --output text > ec2-ssh-key.pem"
}

output "ssh_command" {
  value = "ssh -i ec2-ssh-key.pem -p 4022 ec2-user@${aws_instance.app_server.public_ip}"
}

output "instance_private_ip" {
  value = aws_instance.app_server.private_ip
}