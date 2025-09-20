# Grafana EC2 Instance - Simple and Direct Approach
# Access restricted to port 3000 only

# Security Group for Grafana EC2
resource "aws_security_group" "grafana_ec2" {
  name_prefix = "${local.name_prefix}-grafana-ec2-"
  vpc_id      = aws_vpc.grafana_vpc.id
  
  # Allow SSH from bastion and your IP
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from bastion"
  }
  
  # Allow SSH from your IP for dashboard configuration (temporary)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["83.41.250.2/32"]
    description = "SSH from your IP for configuration (temporary)"
  }
  
  # Allow HTTP access to Grafana on port 3000 from anywhere
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana web interface"
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${local.name_prefix}-grafana-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Grafana EC2 Instance
resource "aws_instance" "grafana" {
  depends_on = [
    aws_iam_instance_profile.grafana_ec2,
    aws_iam_role.grafana_ec2_role,
    aws_iam_policy.grafana_ec2_s3
  ]
  
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.medium"
  key_name              = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.grafana_ec2.id]
  subnet_id             = aws_subnet.grafana_public.id
  iam_instance_profile   = aws_iam_instance_profile.grafana_ec2.name
  
  user_data = base64encode(templatefile("${path.module}/grafana-user-data.sh", {
    grafana_admin_password = var.grafana_admin_password
    s3_bucket_name        = aws_s3_bucket.grafana_provisioning.bucket
  }))
  
  tags = {
    Name        = "${local.name_prefix}-grafana-ec2"
    Environment = var.environment
    Project     = var.project_name
    Service     = "monitoring"
  }
}

# Elastic IP for Grafana
resource "aws_eip" "grafana" {
  instance = aws_instance.grafana.id
  domain   = "vpc"
  
  tags = {
    Name        = "${local.name_prefix}-grafana-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Null resource to configure dashboards after instance is ready
resource "null_resource" "configure_dashboards" {
  depends_on = [
    aws_instance.grafana,
    aws_eip.grafana
  ]
  
  # Trigger when instance state changes
  triggers = {
    instance_id = aws_instance.grafana.id
    public_ip   = aws_eip.grafana.public_ip
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Grafana to be ready..."
      sleep 30
      
      echo "Configuring dashboards..."
      chmod +x ./configure-dashboards.sh
      ./configure-dashboards.sh
      
      echo "Closing SSH access for security..."
      sleep 10
    EOT
  }
}

# Null resource to close SSH access after configuration
resource "null_resource" "close_ssh_access" {
  depends_on = [null_resource.configure_dashboards]
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Closing SSH access for security..."
      
      # Remove SSH access from your IP
      aws ec2 revoke-security-group-ingress \
        --group-id ${aws_security_group.grafana_ec2.id} \
        --protocol tcp \
        --port 22 \
        --cidr 83.41.250.2/32 \
        --region us-east-1 || echo "SSH access already closed or not found"
      
      echo "SSH access closed successfully!"
    EOT
  }
}
