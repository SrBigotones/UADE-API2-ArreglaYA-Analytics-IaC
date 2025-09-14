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

# Bastion Host Public IP
output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion.public_ip
}

# Connection Instructions
output "connection_example" {
  description = "Example commands to connect to the database through the bastion"
  value       = "To connect to the database:\n1. SSH to bastion: ssh ec2-user@${aws_instance.bastion.public_ip}\n2. Then connect to DB: psql -h ${aws_db_instance.postgres.endpoint} -U postgres -d ${aws_db_instance.postgres.db_name}"
}

output "rds_security_group_id" {
  description = "Security Group ID for RDS"
  value       = aws_security_group.rds.id
}

output "lambda_security_group_id" {
  description = "Security Group ID to attach to Lambda to allow DB access"
  value       = aws_security_group.lambda.id
}
