# -----------------------------
#  AWS PROVIDER
# -----------------------------
# Think of this as choosing the country where you use your phone.
provider "aws" {
  region = "us-east-1"
}

# -----------------------------
#  VPC = Your Smartphone
# -----------------------------
# A VPC is like your entire phone. 
# Everything (apps, settings, data) lives inside your phone.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"   # Full memory/storage available
  enable_dns_support   = true            # Phone can resolve names
  enable_dns_hostnames = true            # Phone can show domain names
}

# -----------------------------
#  INTERNET GATEWAY = Wi-Fi / Mobile Data
# -----------------------------
# This is how your phone connects to the internet.
# Without Wi-Fi/Data, your apps cannot go online.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# -----------------------------
#  PUBLIC SUBNET A = App Folder with Internet
# -----------------------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true        # Auto public IP = CAN use Wi-Fi
}

# -----------------------------
#  PUBLIC SUBNET B = Another App Folder With Internet
# -----------------------------
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# -----------------------------
#  PRIVATE SUBNET = App Folder with NO Internet
# -----------------------------
# Apps inside this folder CANNOT access Wi-Fi/Data.
# No public IP + no route to IGW = fully private.
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false       # No public IP = stays private
}

# -----------------------------
#  PUBLIC ROUTE TABLE = Internet Rules
# -----------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"              
    # 0.0.0.0/0 = ALL internet traffic
    # Means: "Any app that needs internet..."

    gateway_id = aws_internet_gateway.igw.id
    # Send traffic to Wi-Fi/Data
  }
}

# -----------------------------
#  PRIVATE ROUTE TABLE = NO INTERNET
# -----------------------------
# IMPORTANT:
# This private route table has NO route to IGW.
# Apps in private subnet can only talk INSIDE the VPC.
# Like a folder in your phone that has ZERO Wi-Fi permissions.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # No 0.0.0.0/0 route here
  # Completely private routing
}

# -----------------------------
#  ROUTE TABLE ASSOCIATIONS
# -----------------------------
# Attach public route table to public subnets (A and B)
# → These folders can use Wi-Fi/Data.
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Attach PRIVATE route table to PRIVATE subnet
# → This folder CANNOT use Wi-Fi/Data.
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------
#  SECURITY GROUP = App Permissions
# -----------------------------
# In your phone, each app asks:
# - Allow camera?
# - Allow notifications?
# - Allow internet?
#
# A security group works the same way.
resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  # INBOUND = What connections are allowed to come IN
  # Like allowing an app to receive internet messages.
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # OUTBOUND = What the app can send OUT
  # Like your app sending notifications.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
