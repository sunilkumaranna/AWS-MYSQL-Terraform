# -----------------------------
# Output: VPC ID
# -----------------------------
# Export the VPC ID so other modules (like DBA) can use it.
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

# -----------------------------
# Output: Public Subnet IDs
# -----------------------------
# DBA module may need access to public subnets
# (for NAT gateways, bastion hosts, or public RDS).
output "public_subnet_ids" {
  description = "List of all public subnet IDs"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

# -----------------------------
# Output: Private Subnet IDs
# -----------------------------
# RDS *must* be deployed in private subnets (recommended)
# Even though you have only *ONE* private subnet now,
# we still return it as a LIST so Terraform does not break.
output "private_subnet_ids" {
  description = "List of all private subnet IDs"
  value = [
    aws_subnet.private_a.id
  ]
}

# -----------------------------
# Output: RDS Security Group
# -----------------------------
# The DBA Terraform module needs the RDS security group
# so it can connect your database instance to the correct SG.
output "rds_sg_id" {
  description = "Security group ID used by RDS instances"
  value       = aws_security_group.rds.id
}