output "db_password_secret_arn" {
  value = aws_secretsmanager_secret.db_passwords.arn
}

output "db_password_secret_name" {
  value = aws_secretsmanager_secret.db_passwords.name
}

output "mysql_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "mssql_endpoint" {
  value = aws_db_instance.mssql_express.endpoint
}

output "postgres_endpoint" {
  value = aws_db_instance.postgres.endpoint
}