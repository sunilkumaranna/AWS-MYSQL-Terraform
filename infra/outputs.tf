output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
  description = "List of public subnet IDs for RDS"
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}
