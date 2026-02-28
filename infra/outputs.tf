output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

output "rds_sg_id" {
  value = aws_security_group.rds.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}