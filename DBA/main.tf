# ============================================================
# AWS PROVIDER
# ============================================================
# Specifies the AWS region where RDS instances will be deployed
provider "aws" {
  region = var.aws_region
}

# ============================================================
# TERRAFORM BACKEND
# ============================================================
# Maintains the DBA Terraform state in S3
terraform {
  backend "s3" {
    bucket  = "my-simple-s3-bucket-sunilanna-2610" # S3 bucket for DBA state
    key     = "dba/terraform.tfstate"               # State file path in bucket
    region  = "us-east-1"                           # AWS region of the bucket
    encrypt = true                                  # Encrypt state at rest
  }
}

# ============================================================
# IMPORT INFRA OUTPUTS
# ============================================================
# Pull VPC, RDS Security Group, and Subnet Group from Infra module
# Only one terraform_remote_state block is needed
data "terraform_remote_state" "infra" {
  backend = "local"                   # Read local state file from Infra
  config = { path = "../infra/terraform.tfstate" }  # Path to Infra state
}

# ============================================================
# SECRETS MANAGER (DB PASSWORDS)
# ============================================================
# Store database passwords for all engines in a single secret
resource "aws_secretsmanager_secret" "db_passwords" {
  name                    = "all-db-passwords"
  recovery_window_in_days = 0  # Immediate deletion possible
}

# Add version of the secret containing passwords
resource "aws_secretsmanager_secret_version" "db_passwords_version" {
  secret_id     = aws_secretsmanager_secret.db_passwords.id
  secret_string = jsonencode({
    mysql_password    = "StrongPassword123!"
    mssql_password    = "StrongPassword456!"
    postgres_password = "StrongPassword789!"
  })
}

# Local map for easier reference of DB passwords
locals {
  db_secrets = jsondecode(aws_secretsmanager_secret_version.db_passwords_version.secret_string)
}

# ============================================================
# RDS INSTANCES (Using Infra Outputs)
# ============================================================

# ---------------------------
# MySQL RDS
# ---------------------------
resource "aws_db_instance" "mysql" {
  identifier                  = "my-mysql-db"            # Unique RDS identifier
  engine                      = "mysql"                  # Engine type
  engine_version              = "8.0"                    # MySQL version
  instance_class              = var.instance_class       # e.g., db.t3.micro
  allocated_storage           = var.allocated_storage    # GB
  storage_type                = var.storage_type         # e.g., gp2
  db_name                     = var.db_name              # Default DB
  username                    = var.db_username          # Admin username
  password                    = local.db_secrets.mysql_password
  publicly_accessible         = true
  skip_final_snapshot         = true                     # No snapshot on delete
  storage_encrypted           = true                     # Encrypt data at rest
  multi_az                    = false
  allow_major_version_upgrade = true
  apply_immediately           = true                     # Apply changes immediately

  # Use Infra outputs
  db_subnet_group_name   = data.terraform_remote_state.infra.outputs.rds_subnet_group_name
  vpc_security_group_ids = [data.terraform_remote_state.infra.outputs.rds_sg_id]
}

# ---------------------------
# MSSQL Express RDS
# ---------------------------
resource "aws_db_instance" "mssql_express" {
  identifier                  = "my-mssql-express-db"
  engine                      = "sqlserver-ex"
  engine_version              = "15.00"
  username                    = var.db_username
  password                    = local.db_secrets.mssql_password
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  storage_type                = var.storage_type
  publicly_accessible         = true
  skip_final_snapshot         = true
  storage_encrypted           = true
  multi_az                    = false
  allow_major_version_upgrade = true
  apply_immediately           = true

  db_subnet_group_name   = data.terraform_remote_state.infra.outputs.rds_subnet_group_name
  vpc_security_group_ids = [data.terraform_remote_state.infra.outputs.rds_sg_id]
}

# ---------------------------
# PostgreSQL RDS
# ---------------------------
resource "aws_db_instance" "postgres" {
  identifier                  = "my-postgres-db"
  engine                      = "postgres"
  engine_version              = "13.15"
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  storage_type                = var.storage_type
  db_name                     = var.db_name
  username                    = var.postgres_username
  password                    = local.db_secrets.postgres_password
  publicly_accessible         = true
  skip_final_snapshot         = true
  storage_encrypted           = true
  multi_az                    = false
  allow_major_version_upgrade = true
  apply_immediately           = true

  db_subnet_group_name   = data.terraform_remote_state.infra.outputs.rds_subnet_group_name
  vpc_security_group_ids = [data.terraform_remote_state.infra.outputs.rds_sg_id]
}