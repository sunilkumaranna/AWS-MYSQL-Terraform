# -----------------------------
# OUTPUTS FILE
# -----------------------------
# Outputs allow OTHER Terraform modules or users
# to easily access important values such as:
# - VPC ID
# - Subnet IDs
# - Security Group ID
# -----------------------------

# VPC ID → Useful for attaching resources like EC2, RDS, ALB, etc.
output "vpc_id" {
  value = aws_vpc.main.id
}

# Public subnets → Used for load balancers, NAT gateways, bastion hosts, etc.
output "public_subnet_ids" {
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

# Private subnets → Best place for RDS and internal applications
output "private_subnet_ids" {
  value = [
    aws_subnet.private_a.id
  ]
}

# RDS security group → Required by any RDS module or EC2 that needs DB access
output "rds_sg_id" {
  value = aws_security_group.rds.id
}