output "db_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "db_port" {
  description = "RDS port"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

output "connection_example" {
  description = "Connection string for the database"
  value       = "Connect directly to DB: psql -h ${aws_db_instance.postgres.endpoint} -U postgres -d ${aws_db_instance.postgres.db_name}"
}
