variable "project_name" {
  description = "Nombre del proyecto."
  type        = string
}

variable "vpc_cidr" {
  description = "Rango CIDR para la VPC."
  type        = string
}

variable "subnet_cidr" {
  description = "Rango CIDR para la subnet pública."
  type        = string
}