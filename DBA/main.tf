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

variable "db_username" { default = "admin" }
variable "db_name" { default = "mydb2" }
variable "allocated_storage" { default = 20 }
variable "instance_class" { default = "db.t3.micro" }

# ---- Secrets Manager ----
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

# ---- Subnet Group ----
resource "aws_db_subnet_group" "rds" {
  name = "rds-subnet-group"

  subnet_ids = data.terraform_remote_state.infra.outputs.public_subnet_ids
}

# ---- RDS Instance ----
resource "aws_db_instance" "mysql" {
  identifier           = "my-mysql-db"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  db_name              = var.db_name
  username             = var.db_username
  password             = local.db_password
  publicly_accessible  = true
  skip_final_snapshot  = true
  storage_encrypted    = true
  multi_az             = false
  db_subnet_group_name = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [
    data.terraform_remote_state.infra.outputs.rds_sg_id
  ]
}
