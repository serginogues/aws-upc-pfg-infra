# =============================================================================
# BASTION HOST CONFIGURATION
# =============================================================================

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name_prefix = "${local.name_prefix}-bastion-"
  vpc_id      = aws_vpc.grafana_vpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access to Grafana (for port forwarding)
  egress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]  # Private subnet CIDR
    description = "HTTP access to Grafana for port forwarding"
  }

  # SSH access to Grafana
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]  # Private subnet CIDR
    description = "SSH access to Grafana"
  }

  # All outbound traffic for internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic for internet access"
  }

  tags = {
    Name        = "${local.name_prefix}-bastion-sg"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Generate SSH key pair for bastion
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Key pair for bastion host
resource "aws_key_pair" "bastion_key" {
  key_name   = "${local.name_prefix}-bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh

  tags = {
    Name        = "${local.name_prefix}-bastion-key"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Save private key to file
resource "local_file" "bastion_private_key" {
  content         = tls_private_key.bastion_key.private_key_pem
  filename        = "${path.module}/bastion-key.pem"
  file_permission = "0400"
}

# EC2 Instance for Bastion Host
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.grafana_public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.bastion_key.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name        = "${local.name_prefix}-bastion"
    Environment = var.environment
    Project     = var.app-name
    Service     = "bastion"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "bastion_public_ip" {
  description = "Public IP of Bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i bastion-key.pem ec2-user@${aws_instance.bastion.public_ip}"
}
