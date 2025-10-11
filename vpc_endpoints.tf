# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "arregla-ya-vpc-endpoints-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id, aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "arregla-ya-vpc-endpoints-sg"
  }
}

# S3 Gateway Endpoint (free)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]

  tags = {
    Name = "arregla-ya-s3-endpoint"
  }
}

# SSM endpoint required for Parameter Store access
resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_1.id]  # Single AZ for cost savings
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name = "arregla-ya-ssm-endpoint"
  }
}

# Route table for private subnets (without NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "arregla-ya-private-rt"
  }
}

# First, remove the existing route table associations
resource "null_resource" "remove_existing_associations" {
  provisioner "local-exec" {
    command = <<EOT
      aws ec2 disassociate-route-table --association-id rtbassoc-06f12ad62470675c8
      aws ec2 disassociate-route-table --association-id rtbassoc-033680f6a5885a8ef
    EOT
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private_1" {
  depends_on = [null_resource.remove_existing_associations]
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  depends_on = [null_resource.remove_existing_associations]
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}