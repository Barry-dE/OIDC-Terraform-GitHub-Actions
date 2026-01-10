output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.oidc_demo_vpc.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.oidc_demo_public_subnet[*].id
  
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.oidc_demo_private_subnet[*].id
  sensitive = true
}