output "db_endpoint" {
  description = "RDS instance endpoint (hostname)"
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "RDS instance port"
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Database name"
  value       = aws_db_instance.postgres.db_name
}

output "rds_security_group_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds.id
}

output "lambda_security_group_id" {
  description = "Security Group ID to attach to Lambda to allow DB access"
  value       = aws_security_group.lambda.id
}
