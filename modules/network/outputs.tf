output "vpc_01_id" {
  value = aws_vpc.vpc_01.id
}
output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.subnet_01.arn
}