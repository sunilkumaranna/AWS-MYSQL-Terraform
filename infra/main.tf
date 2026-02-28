# -----------------------------
#  AWS PROVIDER
# -----------------------------
# Choosing a region is like choosing the COUNTRY where you are using your phone.
# Everything you build (networks, servers, databases) will live in this region.
provider "aws" {
  region = "us-east-1"
}

# -----------------------------
#  VPC = Your Smartphone
# -----------------------------
# A VPC is like your entire phone.
# All apps, settings, files, and data live inside your phone.
# A /16 network means you have a BIG phone with lots of storage space for apps.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"   # The entire memory/storage of your phone
  enable_dns_support   = true            # Phone can resolve website names (DNS)
  enable_dns_hostnames = true            # Phone can display domain names correctly
 tags = {
    Name = "my-vpc-sunil"   # This is how you give your VPC a name in AWS
  }

}

# -----------------------------
#  INTERNET GATEWAY = Wi-Fi / Mobile Data
# -----------------------------
# This is like turning Wi-Fi or Mobile Data ON for your phone.
# Without this, your phone cannot access the internet at all.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# -----------------------------
#  PUBLIC SUBNET A = App Folder WITH Internet
# -----------------------------
# A SUBNET is like a folder inside your phone that groups apps together.
#
# PUBLIC subnet = app folder that CAN use Wi-Fi/Data.
# A public IP is automatically given to anything launched here.
#
# AZ = Availability Zone = A CELL TOWER in the same country.
# "us-east-1a" is like "cell tower A".
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"   # Space inside folder A
  availability_zone       = "us-east-1a"    # Connected to Cell Tower A
  map_public_ip_on_launch = true            # Apps automatically get internet access
tags = {
    Name        = "public_a_sunil"
    Environment = "public_test"
  }
}


# -----------------------------
#  PUBLIC SUBNET B = Another App Folder WITH Internet
# -----------------------------
# This is exactly like Public Subnet A:
# - It also CAN use Wi-Fi/Mobile Data
# - It also gives public IPs automatically
#
# BUT it lives in a DIFFERENT Availability Zone.
# Think of "us-east-1b" as "cell tower B".
#
# This gives high availability:
# If cell tower A goes down → apps in Subnet B still work.
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"   # Space inside folder B
  availability_zone       = "us-east-1b"    # Connected to Cell Tower B
  map_public_ip_on_launch = true            # Apps automatically get internet access
tags = {
    Name        = "public_b_sunil"
    Environment = "public_test"
  }
}

# -----------------------------
#  PRIVATE SUBNET = App Folder with NO Internet
# -----------------------------
# PRIVATE subnet = a folder on your phone with STRICT parental controls:
# - No Wi-Fi
# - No Mobile Data
# - No public IP
#
# Things in this folder CANNOT directly access the internet.
# They can only talk to other things INSIDE THE PHONE (inside the VPC).
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"     # Uses Cell Tower A (still no internet)
  map_public_ip_on_launch = false            # No public IP = no internet access
tags = {
    Name        = "private_a_sunil"
    Environment = "private_test"
  }


}

# -----------------------------
#  PUBLIC ROUTE TABLE = Internet Rules
# -----------------------------
# A ROUTE TABLE is like your phone's "Connectivity Settings".
#
# PUBLIC route table = rules that allow apps IN PUBLIC folders
# to use Wi-Fi/Mobile Data.
#
# The 0.0.0.0/0 rule means:
# "For ANY traffic going to the internet, use the Internet Gateway."
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"            # All internet traffic
    gateway_id = aws_internet_gateway.igw.id   # Use Wi-Fi/Mobile Data
  }
}


# -----------------------------
#  PRIVATE ROUTE TABLE = NO Internet Rules
# -----------------------------
# This route table INTENTIONALLY has NO route to the internet.
#
# Apps in the private folder:
# - Cannot access internet
# - Cannot reach outside the phone
# - Can only talk internally to other subnets or internal services
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  # No route to 0.0.0.0/0 → Means: NO INTERNET EVER
}

# -----------------------------
#  ROUTE TABLE ASSOCIATIONS
# -----------------------------
# These attach each subnet to the correct routing rules.
#
# Public Subnets A & B → PUBLIC route table
# → They CAN use the Internet Gateway.
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Private Subnet → PRIVATE route table
# → It CANNOT use the Internet Gateway.
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# -----------------------------
#  SECURITY GROUP = App Permissions
# -----------------------------
# A Security Group is like permission settings for an app:
#
# - Allow access to microphone?
# - Allow notifications?
# - Allow camera?
#
# For servers/databases, SG controls:
# - Who can connect?
# - On which ports?
# - From where?
#
# Here, we create a Security Group that allows connections
# to a database (port 3306 → MySQL).
resource "aws_security_group" "rds" {
  name   = "rds-sg"
  vpc_id = aws_vpc.main.id

  # INBOUND = Who can talk TO the app.
  # Allow ANYONE (0.0.0.0/0) to connect on port 3306.
  # ⚠️ In real life, this is DANGEROUS → restrict later.
  ingress {
    from_port   = 3306                   # MySQL port
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]          # Allow from anywhere
  }

  # OUTBOUND = What the app can talk OUT to.
  # Here, allow all outbound traffic (default AWS behavior).
  egress {
    from_port   = 0                      # ALL ports
    to_port     = 0
    protocol    = "-1"                   # -1 = ALL protocols
    cidr_blocks = ["0.0.0.0/0"]          # Allow to anywhere
  }
}