# -----------------------------
#  AWS PROVIDER
# -----------------------------
# The AWS provider tells Terraform which AWS REGION to deploy into.
# Choosing a region is like choosing the COUNTRY where you're using your phone.
provider "aws" {
  region = "us-east-1"
}

# -----------------------------
#  VPC = Your Smartphone
# -----------------------------
# A VPC is like your entire phone.
# Everything you deploy (servers, subnets, databases) lives inside it.
# /16 = very large network space with many possible subnets.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true      # Phone can resolve website names (DNS)
  enable_dns_hostnames = true      # Instances get DNS hostnames

  tags = {
    Name = "my-vpc-sunil"
  }
}

# -----------------------------
#  INTERNET GATEWAY = Wi-Fi / Mobile Data
# -----------------------------
# This is the component that allows the VPC to access the internet.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-vpc-sunil-gateway"
  }
}

# -----------------------------
#  PUBLIC SUBNET A
# -----------------------------
# A public subnet = folder on your phone where apps CAN use Wi-Fi/Mobile Data.
# Anything launched here gets a public IP by default.
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"   # Connected to "cell tower A"
  map_public_ip_on_launch = true           # Auto-assign public IP

  tags = {
    Name        = "public_a_sunil"
    Environment = "public_test"
  }
}

# -----------------------------
#  PUBLIC SUBNET B
# -----------------------------
# Same as A, but in a different AZ for HIGH AVAILABILITY.
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"   # Connected to "cell tower B"
  map_public_ip_on_launch = true

  tags = {
    Name        = "public_b_sunil"
    Environment = "public_test"
  }
}

# -----------------------------
#  PRIVATE SUBNET A
# -----------------------------
# Private subnet = folder with NO internet.
# No public IP → Cannot talk to internet unless NAT Gateway is added.
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false          # No internet access

  tags = {
    Name        = "private_a_sunil"
    Environment = "private_test"
  }
}

# -----------------------------
#  PUBLIC ROUTE TABLE
# -----------------------------
# Public route table = rules allowing PUBLIC subnets to reach the internet.
# 0.0.0.0/0 → "send all external traffic to the internet gateway".
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"               # All internet traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table-sunil"
  }
}

# -----------------------------
#  PRIVATE ROUTE TABLE
# -----------------------------
# No internet access here because we do NOT add a 0.0.0.0/0 route.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-route-table-sunil"
  }
}

# -----------------------------
#  ROUTE TABLE ASSOCIATIONS
# -----------------------------
# These ensure each subnet uses the correct route table.

# Public subnets → Public route table (internet allowed)
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Private subnets → Private route table (NO internet)
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------
#  SECURITY GROUP = App Permissions
# -----------------------------
# SG = controls who can talk to your resource.
#
# ⚠️ Your previous SG allowed 0.0.0.0/0 on port 3306.
#    That exposes the database to the whole world.
#    This is extremely dangerous.
#
# In this safer version:
# - Only the **public subnets** can connect to RDS.
# - You can modify allowed ranges later if needed.
resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  # Allow INBOUND MySQL traffic ONLY from inside the VPC.
  ingress {
    from_port   = 3306          # MySQL port
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [
      "10.0.1.0/24",            # Public subnet A
      "10.0.2.0/24"             # Public subnet B
    ]
  }

  # Allow OUTBOUND everywhere (default AWS behavior)
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