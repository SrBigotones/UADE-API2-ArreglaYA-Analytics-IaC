# EC2 Instance for Grafana and Prometheus
resource "aws_instance" "monitoring" {
  ami           = "ami-0c7217cdde317cfec"  # Amazon Linux 2023 AMI
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id
  key_name      = "arregla-ya-bastion-key"

  user_data = <<-EOF
              #!/bin/bash
              # Update system and install required packages
              dnf update -y
              dnf install -y docker git nc

              # Install Docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Wait for Docker to be fully operational
              timeout 60 bash -c 'until docker info; do sleep 2; done'

              # Create directories
              mkdir -p /opt/grafana/provisioning/datasources
              mkdir -p /opt/grafana/provisioning/dashboards
              mkdir -p /opt/prometheus
              chown -R ec2-user:ec2-user /opt/grafana /opt/prometheus

              # Create Prometheus config
              cat > /opt/prometheus/prometheus.yml <<EOL
              global:
                scrape_interval: 15s
                scrape_timeout: 10s
                evaluation_interval: 15s

              scrape_configs:
                - job_name: 'prometheus'
                  static_configs:
                    - targets: ['localhost:9090']

                - job_name: 'node'
                  static_configs:
                    - targets: ['localhost:9100']
              EOL

              # Create Grafana datasource config
              cat > /opt/grafana/provisioning/datasources/datasource.yml <<EOL
              apiVersion: 1
              datasources:
                - name: Prometheus
                  type: prometheus
                  access: proxy
                  url: http://localhost:9090
                  isDefault: true
                - name: PostgreSQL
                  type: postgres
                  url: ${aws_db_instance.postgres.endpoint}
                  database: arregla_ya_analytics
                  user: stage_user
                  secureJsonData:
                    password: 'iX4E,``|7-3V``'
                  jsonData:
                    sslmode: 'require'
              EOL

              # Start Grafana
              docker run -d \
                --name grafana \
                -p 3000:3000 \
                -v /opt/grafana:/var/lib/grafana \
                -v /opt/grafana/provisioning:/etc/grafana/provisioning \
                -e "GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource" \
                grafana/grafana-oss

              # Start Prometheus
              docker run -d \
                --name prometheus \
                -p 9090:9090 \
                -v /opt/prometheus:/etc/prometheus \
                prom/prometheus --config.file=/etc/prometheus/prometheus.yml

              # Start Node Exporter
              docker run -d \
                --name node-exporter \
                -p 9100:9100 \
                -v "/proc:/host/proc:ro" \
                -v "/sys:/host/sys:ro" \
                -v "/:/rootfs:ro" \
                --net="host" \
                prom/node-exporter \
                --path.procfs=/host/proc \
                --path.sysfs=/host/sys \
                --collector.filesystem.mount-points-exclude="^/(sys|proc|dev|host|etc)($$|/)"

              # SSH setup
              mkdir -p /home/ec2-user/.ssh
              echo '${var.ssh_public_key}' >> /home/ec2-user/.ssh/authorized_keys
              chmod 700 /home/ec2-user/.ssh
              chmod 600 /home/ec2-user/.ssh/authorized_keys
              chown -R ec2-user:ec2-user /home/ec2-user/.ssh
              EOF

  iam_instance_profile = aws_iam_instance_profile.grafana.name

  vpc_security_group_ids = [aws_security_group.monitoring.id]

  root_block_device {
    volume_size = 20  # GB
    volume_type = "gp3"
  }

  tags = {
    Name = "arregla-ya-monitoring"
  }

  # Ensure the instance has internet connectivity before running user_data
  depends_on = [
    aws_route_table.public
  ]
}

# Security Group for Monitoring Instance
resource "aws_security_group" "monitoring" {
  name        = "arregla-ya-monitoring"
  description = "Security group for Grafana and Prometheus"
  vpc_id      = aws_vpc.main.id

  # SSH Access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # Grafana Web Interface
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana web access"
  }

  # Prometheus Web Interface
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Prometheus web access"
  }

  # Node Exporter
  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Node Exporter metrics"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "arregla-ya-monitoring"
  }
}

# Create a key pair for SSH access
resource "aws_key_pair" "monitoring" {
  key_name   = "arregla-ya-monitoring-key"
  public_key = var.ssh_public_key
}

# Output the IPs for reference
output "monitoring_public_ip" {
  description = "Public IP of the monitoring instance"
  value       = aws_instance.monitoring.public_ip
}

output "grafana_url" {
  description = "URL for Grafana web interface"
  value       = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "prometheus_url" {
  description = "URL for Prometheus web interface"
  value       = "http://${aws_instance.monitoring.public_ip}:9090"
}