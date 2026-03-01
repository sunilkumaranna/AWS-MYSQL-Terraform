# ============================================================
# infra VARIABLES FILE
# ============================================================
# Variables allow flexibility.
# You can reuse this module for any environment just by changing values.

variable "aws_region" {
  description = "AWS region where resources will be created"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_a_cidr" {
  description = "CIDR block for public subnet A"
  default     = "10.0.1.0/24"
}

variable "public_b_cidr" {
  description = "CIDR block for public subnet B"
  default     = "10.0.2.0/24"
}

variable "private_a_cidr" {
  description = "CIDR block for private subnet A"
  default     = "10.0.3.0/24"
}

variable "private_b_cidr" {
  description = "CIDR block for private subnet B"
  default     = "10.0.4.0/24"
}