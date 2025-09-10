terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

#############################
# VPC and Networking (kept) #
#############################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "arregla-ya-vpc"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "arregla-ya-private-1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "arregla-ya-private-2"
  }
}

########################################
# Security Groups (lock down the DB)   #
########################################

# SG intended to be attached to your Lambda functions in this VPC.
# Attach this SG to your Lambda so it can reach the DB.
resource "aws_security_group" "lambda" {
  name        = "arregla-ya-lambda-sg"
  description = "Security group for Lambdas that need DB access"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "arregla-ya-lambda-sg"
  }
}

# DB SG: only allow Postgres from the Lambda SG
resource "aws_security_group" "rds" {
  name        = "arregla-ya-rds-sg"
  description = "Security group for RDS PostgreSQL - restricted to Lambda SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "arregla-ya-rds-sg"
  }
}

########################
# DB Subnet Group (RDS)#
########################

resource "aws_db_subnet_group" "rds" {
  name       = "arregla-ya-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "ArreglaYa RDS subnet group"
  }
}

#######################################
# Cheapest: RDS PostgreSQL instance   #
#######################################
# Single-AZ, db.t4g.micro (free-tier eligible), in private subnets.
# Public access disabled; security via SG above.
resource "aws_db_instance" "postgres" {
  identifier                  = "arregla-ya-postgres"
  engine                      = "postgres"
  # Let AWS pick a recent engine_version for availability; pin later if desired.
  instance_class              = "db.t4g.micro"
  allocated_storage           = 20
  max_allocated_storage       = 100
  storage_type                = "gp3"
  db_subnet_group_name        = aws_db_subnet_group.rds.name
  vpc_security_group_ids      = [aws_security_group.rds.id]
  publicly_accessible         = false
  multi_az                    = false

  db_name                     = var.db_name
  username                    = var.db_username
  password                    = var.db_password

  # Cost + dev-friendly settings
  backup_retention_period     = 1
  copy_tags_to_snapshot       = true
  auto_minor_version_upgrade  = true
  deletion_protection         = false
  apply_immediately           = true
  skip_final_snapshot         = true

  # Keep monitoring/PI off for cost
  performance_insights_enabled = false
  monitoring_interval          = 0

  tags = {
    Name = "ArreglaYa PostgreSQL t4g.micro"
    Environment = "dev"
    CostOptimized = "true"
  }
}
