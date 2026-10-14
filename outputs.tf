output "vpc_id" {
  description = "VPC ID for application integration."
  value       = aws_vpc.main_vpc.id
}
output "public_subnet_ids" {
  description = "Public subnet IDs in availability_zones order."
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}
output "private_subnet_ids" {
  description = "Private subnet IDs in availability_zones order."
  value       = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
}
output "public_route_table_id" {
  value = aws_route_table.public_rt.id
}
output "private_route_table_ids" {
  value = [aws_route_table.private_rt_1.id, aws_route_table.private_rt_2.id]
}
