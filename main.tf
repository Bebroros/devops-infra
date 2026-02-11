terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~>5"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-north-1"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.aws_ssh_keys_location)
}

resource "aws_security_group" "web-server" {
  name = "web-server"

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "app" {
  name = "app"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web-server.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "web-server" {
  ami                    = "ami-073130f74f5ffb161"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web-server.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              echo "<h1>WEB SERVER</h1>" > /var/www/html/index.html
              systemctl enable nginx
              systemctl start nginx
              EOF


  tags = {
    Name = "Web Server"
  }
}

resource "aws_instance" "app" {
  ami                    = "ami-073130f74f5ffb161"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              sed -i 's/80 default_server/8080 default_server/g' /etc/nginx/sites-enabled/default
              echo "<h1>APP SERVER</h1>" > /var/www/html/index.html
              systemctl restart nginx
              EOF

  tags = {
    Name = "App"
  }
}

output "web-server_public_ip" {
  value = aws_instance.web-server.public_ip
}

output "app_public_ip" {
  value = aws_instance.app.public_ip
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}


resource "aws_route53_zone" "aws" {
  name = "aws.bebroros.pp.ua"
}

data "cloudflare_zone" "main" {
  filter = {
    name = "bebroros.pp.ua"
  }
}

resource "cloudflare_dns_record" "ns0" {
  zone_id = data.cloudflare_zone.main.id
  name    = "aws.bebroros.pp.ua"
  content   = aws_route53_zone.aws.name_servers[0]
  type    = "NS"
  proxied = false
  ttl = 60
}

resource "cloudflare_dns_record" "ns1" {
  zone_id = data.cloudflare_zone.main.id
  name    = "aws.bebroros.pp.ua"
  content   = aws_route53_zone.aws.name_servers[1]
  type    = "NS"
  proxied = false
  ttl = 60
}

resource "cloudflare_dns_record" "ns2" {
  zone_id = data.cloudflare_zone.main.id
  name    = "aws.bebroros.pp.ua"
  content   = aws_route53_zone.aws.name_servers[2]
  type    = "NS"
  proxied = false
  ttl = 60
}

resource "cloudflare_dns_record" "ns3" {
  zone_id = data.cloudflare_zone.main.id
  name    = "aws.bebroros.pp.ua"
  content   = aws_route53_zone.aws.name_servers[3]
  type    = "NS"
  proxied = false
  ttl = 60
}

resource "aws_route53_record" "web-server" {
  zone_id = aws_route53_zone.aws.zone_id
  name    = "web-server.aws.bebroros.pp.ua"
  type    = "A"
  ttl     = 60
  records = [aws_instance.web-server.public_ip]
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.aws.zone_id
  name    = "app.aws.bebroros.pp.ua"
  type    = "A"
  ttl     = 60
  records = [aws_instance.app.public_ip]
}