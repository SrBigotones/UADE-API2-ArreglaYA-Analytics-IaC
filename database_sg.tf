resource "aws_security_group" "postgres" {
  name        = "arregla-ya-postgres"
  description = "Security group for PostgreSQL RDS"

  # Allow PostgreSQL access from anywhere (you might want to restrict this to your IP)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Por seguridad, deberías cambiar esto a tu IP específica
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ArreglaYa PostgreSQL"
  }
}