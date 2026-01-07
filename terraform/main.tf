# main.tf - Fully self-contained AWS deployment (no default VPC needed)

provider "aws" {
  region = "us-east-1"
}

# Create a new VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "DevOps-Flask-VPC"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "DevOps-Flask-IGW"
  }
}

# Create a public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "DevOps-Flask-Subnet"
  }
}

# Create a route table for public traffic
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "DevOps-Flask-Public-RT"
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security group (allow HTTP + SSH)
resource "aws_security_group" "flask_sg" {
  name        = "flask-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "flask_server" {
  ami                    = "ami-08d4ac5b634553e16"  # Amazon Linux 2023 (us-east-1)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.flask_sg.id]
  associate_public_ip_address = true

    user_data = <<-EOF
    #!/bin/bash
    echo "Starting setup..." >> /var/log/user-data.log
    yum update -y
    yum install -y docker git
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user

    # Install retry logic
    retry_count=0
    max_retries=5
    until docker pull fanninggh/flask-hello-devops:latest || [ $retry_count -eq $max_retries ]; do
      echo "Retrying Docker pull... ($((retry_count+1))/$max_retries)" >> /var/log/user-data.log
      retry_count=$((retry_count+1))
      sleep 10
    done

    docker run -d -p 80:5000 --name flask-app fanninggh/flask-hello-devops:latest
    echo "Setup complete." >> /var/log/user-data.log
  EOF

  tags = {
    Name = "Flask-DevOps-Server"
  }
}

output "public_ip" {
  value = aws_instance.flask_server.public_ip
}
