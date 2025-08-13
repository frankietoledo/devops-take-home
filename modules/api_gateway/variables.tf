variable "project_name" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "target_instance_id" {
  description = "ID de la instancia EC2 que será el destino del NLB."
  type        = string
}

variable "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  type        = string
}