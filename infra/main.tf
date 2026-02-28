# ============================================================
#  AWS PROVIDER
# ============================================================
# The AWS provider tells Terraform which AWS REGION to deploy into.
# Choosing a region is like choosing the COUNTRY where your phone connects.
provider "aws" {
  region = var.aws_region
}

# ============================================================
#  VPC = Your Smartphone
# ============================================================
# A VPC is like your entire phone.
# Everything you create (servers, subnets, databases) lives inside it.
# /16 means you have a BIG phone with lots of storage (IP addresses).
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true          # Phone can resolve domain names (DNS)
  enable_dns_hostnames = true          # Instances get hostnames automatically

  tags = {
    Name = "my-vpc-sunil"
  }
}

# ============================================================
#  INTERNET GATEWAY = Wi-Fi / Mobile Data Switch
# ============================================================
# An Internet Gateway is like enabling Wi-Fi or mobile data.
# Without this, NOTHING inside the VPC can reach the internet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-vpc-sunil-gateway"
  }
}

# ============================================================
#  PUBLIC SUBNET A
# ============================================================
# Public subnet = folder on your phone that CAN use internet.
# Apps here get a public IP automatically.
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_a_cidr
  availability_zone       = "us-east-1a"   # Cell tower A
  map_public_ip_on_launch = true           # Auto public IP

  tags = {
    Name        = "public_a_sunil"
    Environment = "public"
  }
}

# ============================================================
#  PUBLIC SUBNET B (High availability)
# ============================================================
# Exactly like Public A — but in another AZ.
# If AZ-A goes down, apps in AZ-B still work.
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_b_cidr
  availability_zone       = "us-east-1b"   # Cell tower B
  map_public_ip_on_launch = true

  tags = {
    Name        = "public_b_sunil"
    Environment = "public"
  }
}

# ============================================================
#  PRIVATE SUBNET A (NO Internet)
# ============================================================
# Private subnet = folder on your phone with strict parental controls.
# No public IP → no internet → better security.
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_a_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false          # No internet

  tags = {
    Name        = "private_a_sunil"
    Environment = "private"
  }
}

# ============================================================
#  PRIVATE SUBNET B (Needed for RDS)
# ============================================================
# RDS requires at least **two subnets in two different AZs**
# for Multi-AZ capability and failover safety.
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
#  PUBLIC ROUTE TABLE
# ============================================================
# This is like "Internet Settings" for public subnets.
# 0.0.0.0/0 means:
#   "Any traffic going OUTSIDE should use the Internet Gateway (Wi-Fi/Data)"
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"               # All outside traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table-sunil"
  }
}

# ============================================================
#  PRIVATE ROUTE TABLE
# ============================================================
# No default route to the internet → total isolation.
# Perfect for databases and internal workloads.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table-sunil"
  }
}

# ============================================================
#  ROUTE TABLE ASSOCIATIONS
# ============================================================
# Attach correct routing rules to each subnet.

# Public → uses Public route table
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Private → uses Private route table
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ============================================================
#  SECURITY GROUP FOR RDS = App Permissions
# ============================================================
# A Security Group is like app permission settings on your phone.
# Example:
# - Allow microphone?
# - Allow camera?
#
# Here it means:
# - Who is allowed to connect to the database?
# - On which port?
#
# This SG allows MySQL traffic ONLY from inside the VPC.
resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  # Allow MySQL access from internal private subnets only.
  ingress {
    from_port   = 3306          # MySQL
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [
      var.public_a_cidr,
      var.public_b_cidr
    ]
  }

  # Allow everything outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg-sunil"
  }
}

# ============================================================
#  RDS SUBNET GROUP (REQUIRED FOR RDS SETUP)
# ============================================================
# RDS requires a "DB Subnet Group" to know which private
# subnets it can launch inside.
#
# MUST include at least **two subnets in different AZs**.
resource "aws_db_subnet_group" "rds" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "rds-subnet-group-sunil"
  }
}