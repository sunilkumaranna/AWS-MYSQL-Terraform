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
# VARIABLES
# ---------------------------
variable "db_username" { default = "admin" }
variable "db_name" { default = "mydb2" }
variable "allocated_storage" { default = 20 }
variable "instance_class" { default = "db.t3.micro" }

# ---------------------------
# MYSQL SECRETS
# ---------------------------
resource "aws_secretsmanager_secret" "db_password" {
  name = "mysql-db-password"
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({ password = "StrongPassword123!" })
}

locals {
  db_password = jsondecode(aws_secretsmanager_secret_version.db_password_version.secret_string).password
}

# ---------------------------
# MSSQL SECRETS
# ---------------------------
resource "aws_secretsmanager_secret" "mssql_password" {
  name = "mssql-db-password"
}

resource "aws_secretsmanager_secret_version" "mssql_password_version" {
  secret_id     = aws_secretsmanager_secret.mssql_password.id
  secret_string = jsonencode({ password = "StrongPassword456!" })
}

locals {
  mssql_password = jsondecode(aws_secretsmanager_secret_version.mssql_password_version.secret_string).password
}

# ---------------------------
# SUBNET GROUP
# ---------------------------
resource "aws_db_subnet_group" "rds" {
  name = "rds-subnet-group"

  subnet_ids = data.terraform_remote_state.infra.outputs.public_subnet_ids
}

# ---------------------------
# MYSQL RDS INSTANCE
# ---------------------------
resource "aws_db_instance" "mysql" {
  identifier           = "my-mysql-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  db_name              = var.db_name
  username             = var.db_username
  password             = local.db_password
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
# SQL SERVER EXPRESS RDS INSTANCE
# ---------------------------
resource "aws_db_instance" "mssql_express" {
  identifier           = "my-mssql-express-db"
  engine               = "sqlserver-ex"
  engine_version       = "15.00" # SQL Server 2019 Express
  instance_class       = "db.t3.small"
  allocated_storage    = 20
  storage_type         = "gp2"
  username             = "sa"
  password             = local.mssql_password
  # REMOVE db_name — SQL Server does not allow it
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