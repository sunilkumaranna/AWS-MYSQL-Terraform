# ============================================================
# AWS Region
# ============================================================
# Specify the AWS region where RDS instances should be deployed.
variable "aws_region" {
  description = "AWS region for RDS instances"
  type        = string
  default     = "us-east-1"   # Change if needed
}

# ============================================================
# RDS Instance Type
# ============================================================
# Choose the instance type for all RDS instances
variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

# ============================================================
# RDS Storage
# ============================================================
# Storage size in GB
variable "allocated_storage" {
  description = "Allocated storage size for RDS instances (in GB)"
  type        = number
  default     = 20
}

# Storage type (gp2, gp3, or standard)
variable "storage_type" {
  description = "Type of storage for RDS instances (gp2, gp3, or standard)"
  type        = string
  default     = "gp2"
}

# ============================================================
# Database Names & Users
# ============================================================
# MySQL/Postgres DB name
variable "db_name" {
  description = "Default database name for MySQL/PostgreSQL"
  type        = string
  default     = "mydb"
}

# MySQL/MSSQL username
variable "db_username" {
  description = "Username for MySQL and MSSQL RDS instances"
  type        = string
  default     = "admin"
}

# PostgreSQL username
variable "postgres_username" {
  description = "Username for PostgreSQL RDS instance"
  type        = string
  default     = "postgres_admin"
}