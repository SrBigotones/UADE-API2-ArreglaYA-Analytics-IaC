resource "aws_db_instance" "postgres" {
  identifier             = "arregla-ya-postgres"
  engine                 = "postgres"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  publicly_accessible    = true
  
  db_name               = var.db_name
  username             = var.db_username
  password             = var.db_password

  # Network & Security
  vpc_security_group_ids = [aws_security_group.postgres.id]

  backup_retention_period = 1
  skip_final_snapshot    = true
  apply_immediately      = true
  
  tags = {
    Name = "ArreglaYa PostgreSQL"
  }
}