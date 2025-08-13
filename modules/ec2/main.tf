resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Permite trafico SSH (4022) y App (3000) desde la VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH on custom port"
    from_port   = 4022
    to_port     = 4022
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description      = "App port from within VPC (for NLB)"
    from_port        = 3000
    to_port          = 3000
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

resource "tls_private_key" "app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "${var.project_name}-instance-key"
  public_key = tls_private_key.app_key.public_key_openssh
}

resource "aws_secretsmanager_secret" "private_key_secret" {
  name = "${var.project_name}-private_key"
  recovery_window_in_days= 0
}

resource "aws_secretsmanager_secret_version" "private_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.private_key_secret.id
  secret_string = tls_private_key.app_key.private_key_pem
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name               = aws_key_pair.generated_key.key_name

user_data = <<-EOF
              #!/bin/bash
              # Actualiza los paquetes del sistema
              sudo dnf update -y
              
              # Cambia el puerto de SSH a 4022
              sudo sed -i 's/#Port 22/Port 4022/g' /etc/ssh/sshd_config
              sudo systemctl restart sshd

              # Instala Docker y Docker Compose
              sudo dnf install docker -y
              sudo systemctl enable docker --now
              sudo usermod -a -G docker ec2-user
              
              # Docker Compose viene como un plugin de Docker en AL2023
              sudo dnf install docker-compose-plugin -y

              # Instala Node.js 18 (disponible en los repositorios por defecto de AL2023)
              sudo dnf install nodejs -y
              
              # Crea la aplicación de ejemplo
              mkdir /home/ec2-user/app
              cat << 'EOT' > /home/ec2-user/app/index.js
              const http = require('http');
              const server = http.createServer((req, res) => {
                const routes = {
                  'GET:/': { message: 'Root path GET successful!' },
                  'POST:/webhook': { message: 'Webhook received!' },
                  'GET:/oauth/authorize': { message: 'OAuth Authorize GET successful!' },
                  'GET:/oauth/callback': { message: 'OAuth Callback GET successful!' }
                };
                
                const route = routes[`$${req.method}:$${req.url.split('?')[0]}`];
                
                if (route) {
                  res.writeHead(200, { 'Content-Type': 'application/json' });
                  res.end(JSON.stringify(route));
                } else {
                  res.writeHead(404, { 'Content-Type': 'application/json' });
                  res.end(JSON.stringify({ message: 'Not Found' }));
                }
              });
              server.listen(3000, '0.0.0.0', () => console.log('Server running on port 3000'));
              EOT
              
              # Instala PM2 para mantener la app corriendo
              sudo npm install pm2 -g
              sudo chown -R ec2-user:ec2-user /home/ec2-user/app
              
              # Ejecuta la app como el usuario 'ec2-user'
              runuser -l ec2-user -c 'pm2 start /home/ec2-user/app/index.js'
              EOF
  tags = {
    Name = "${var.project_name}-instance"
  }
}