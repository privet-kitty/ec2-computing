terraform {
  required_version = "~> 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.41.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.2.1"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Name        = "${var.unique_name}"
      ProjectCode = var.project_code
    }
  }
}

data "http" "ifconfig" {
  url = "http://ipv4.icanhazip.com/"
}


locals {
  current_ip         = chomp(data.http.ifconfig.response_body)
  allowed_cidr_guard = var.allowed_cidr == null ? "${local.current_ip}/32" : var.allowed_cidr
  user               = "ubuntu"
  private_key_path   = "./computing_key"
  public_key_path    = "./computing_key.pub"
}



resource "tls_private_key" "remote_generated_key" {
  algorithm = "RSA"
}

resource "aws_vpc" "computing_vpc" {
  cidr_block                       = "172.31.0.0/16"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"
  instance_tenancy                 = "default"
  assign_generated_ipv6_cidr_block = "false"
}

resource "aws_subnet" "public_subnet" {
  vpc_id                          = aws_vpc.computing_vpc.id
  cidr_block                      = "172.31.0.0/20"
  assign_ipv6_address_on_creation = "false"
  map_public_ip_on_launch         = "true"
  # availability_zone can't be fixed because the region isn't fixed either.
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.computing_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.computing_igw.id
  }
}

resource "aws_main_route_table_association" "public_rt_vpc" {
  vpc_id         = aws_vpc.computing_vpc.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_public_subnet" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_internet_gateway" "computing_igw" {
  vpc_id = aws_vpc.computing_vpc.id
}

resource "aws_security_group" "allow_computing_port" {
  description = "Allow traffic for computing environment"
  vpc_id      = aws_vpc.computing_vpc.id
  ingress { # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr_guard]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ssm_parameter" "ubuntu_focal" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "aws_key_pair" "computing_key" {
  key_name   = var.unique_name
  public_key = file(local.public_key_path)
}

resource "aws_instance" "computing_server" {
  ami                    = data.aws_ssm_parameter.ubuntu_focal.value
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_computing_port.id]
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.computing_key.id
  user_data              = file("initialize.sh")

  provisioner "file" {
    content     = var.remote_key_path == null ? tls_private_key.remote_generated_key.private_key_openssh : file(var.remote_key_path.private)
    destination = "/home/${local.user}/.ssh/id_rsa"

    connection {
      type        = "ssh"
      user        = local.user
      private_key = file(local.private_key_path)
      host        = self.public_dns
    }
  }

  provisioner "file" {
    content     = var.remote_key_path == null ? tls_private_key.remote_generated_key.public_key_openssh : file(var.remote_key_path.public)
    destination = "/home/${local.user}/.ssh/id_rsa.pub"

    connection {
      type        = "ssh"
      user        = local.user
      private_key = file(local.private_key_path)
      host        = self.public_dns
    }
  }
}

output "public_ip" {
  value = aws_instance.computing_server.public_ip
}

output "public_dns" {
  value = aws_instance.computing_server.public_dns
}

output "allowed_cidr_guard" {
  value = local.allowed_cidr_guard
}

output "ssh_destination" {
  value = "${local.user}@${aws_instance.computing_server.public_ip}"
}
