# ============================================================
# AWS PROVIDER
# ============================================================
# Terraform needs to know which AWS region to deploy resources in.
# Like selecting the country where your cloud resources will live.
provider "aws" {
  region = var.aws_region
}

# ============================================================
# VPC (Virtual Private Cloud) = Your Cloud "Phone"
# ============================================================
# /16 CIDR allows a large number of IP addresses for subnets, servers, and databases
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true  # DNS resolution enabled
  enable_dns_hostnames = true  # Instances get hostnames automatically

  tags = {
    Name = "my-vpc-sunil"
  }
}

# ============================================================
# INTERNET GATEWAY = Internet Access
# ============================================================
# Allows public subnets to access the Internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-vpc-sunil-gateway"
  }
}

# ============================================================
# PUBLIC SUBNETS (High Availability)
# ============================================================
# Public subnets automatically assign public IPs for internet access
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_a_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public_a_sunil"
    Environment = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_b_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public_b_sunil"
    Environment = "public"
  }
}

# ============================================================
# PRIVATE SUBNETS (For RDS / Internal Services)
# ============================================================
# Private subnets do not assign public IPs
# These are used for databases and sensitive services
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_a_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "private_a_sunil"
    Environment = "private"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_b_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "private_b_sunil"
    Environment = "private"
  }
}

# ============================================================
# ROUTE TABLES
# ============================================================
# Public route table routes traffic to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"  # Route all outbound traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "public-route-table-sunil" }
}

# Private route table has no internet route (isolated)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "private-route-table-sunil" }
}

# ============================================================
# ROUTE TABLE ASSOCIATIONS
# ============================================================
# Attach public route table to public subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Attach private route table to private subnets
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# SECURITY GROUP FOR RDS
# ============================================================
# Controls who can connect to RDS and which ports
resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  # MySQL access from public subnets
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.public_a_cidr, var.public_b_cidr]
  }

  # MSSQL access from public subnets
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.public_a_cidr, var.public_b_cidr]
  }

  # PostgreSQL access from public subnets
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.public_a_cidr, var.public_b_cidr]
  }

  # Outbound: allow all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "rds-sg-sunil" }
}

# ============================================================
# RDS SUBNET GROUP
# ============================================================
# Required for launching RDS in multiple private subnets
resource "aws_db_subnet_group" "rds" {
  # name = "rds-subnet-group"  <-- REMOVE THIS LINE
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "rds-subnet-group-sunil"
  }
}