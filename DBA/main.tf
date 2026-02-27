provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket  = "my-simple-s3-bucket-sunilanna-2610"
    key     = "dba/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# ---------------------------
# COMBINED SECRETS
# ---------------------------
resource "aws_secretsmanager_secret" "db_passwords" {
  name = "all-db-passwords"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_passwords_version" {
  secret_id = aws_secretsmanager_secret.db_passwords.id

  secret_string = jsonencode({
    mysql_password     = "StrongPassword123!"
    mssql_password     = "StrongPassword456!"
    postgres_password  = "StrongPassword789!"
  })
}

locals {
  db_secrets = jsondecode(aws_secretsmanager_secret_version.db_passwords_version.secret_string)
}

# ---------------------------
# SUBNET GROUP
# ---------------------------
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = data.terraform_remote_state.infra.outputs.public_subnet_ids
}


# ---------------------------
# MYSQL RDS
# ---------------------------
resource "aws_db_instance" "mysql" {
  identifier           = "my-mysql-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = var.storage_type
  db_name              = var.db_name
  username             = var.db_username
  password             = local.db_secrets.mysql_password
  publicly_accessible  = true
  skip_final_snapshot  = true
  storage_encrypted    = true
  multi_az             = false
  allow_major_version_upgrade = true
  apply_immediately    = true
  db_subnet_group_name = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [
    data.terraform_remote_state.infra.outputs.rds_sg_id
  ]
}

# ---------------------------
# MSSQL EXPRESS RDS
# ---------------------------
resource "aws_db_instance" "mssql_express" {
  identifier           = "my-mssql-express-db"
  engine               = "sqlserver-ex"
  engine_version       = "15.00"
  username             = var.db_username
  password             = local.db_secrets.mssql_password
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = var.storage_type
  vpc_security_group_ids = [data.terraform_remote_state.infra.outputs.rds_sg_id]
  db_subnet_group_name = aws_db_subnet_group.rds.name
  publicly_accessible  = true
  skip_final_snapshot  = true
  storage_encrypted    = true
  multi_az             = false
  allow_major_version_upgrade = true
  apply_immediately    = true
}

# ---------------------------
# POSTGRESQL RDS
# ---------------------------
resource "aws_db_instance" "postgres" {
  identifier           = "my-postgres-db"
  engine               = "postgres"
  engine_version       = "13.15"
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = var.storage_type
  db_name              = var.db_name
  username             = var.postgres_username
  password             = local.db_secrets.postgres_password
  publicly_accessible  = true
  skip_final_snapshot  = true
  storage_encrypted    = true
  multi_az             = false
  allow_major_version_upgrade = true
  apply_immediately    = true
  db_subnet_group_name = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [
    data.terraform_remote_state.infra.outputs.rds_sg_id
  ]
}