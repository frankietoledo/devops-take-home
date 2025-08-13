terraform {
  backend "s3" {
    bucket = "tf-state-fuse-20250803"
    key    = "global/app/terraform.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.10"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  vpc_cidr     = "10.0.0.0/16"
  subnet_cidr  = "10.0.1.0/24"
}
module "ec2" {
  source = "./modules/ec2"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr
  subnet_id    = module.vpc.public_subnet_id
}
module "api_gateway" {
  source = "./modules/api_gateway"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_id
  target_instance_id = module.ec2.instance_id
  instance_private_ip = module.ec2.instance_private_ip
}