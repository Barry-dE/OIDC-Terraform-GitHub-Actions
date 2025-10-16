# Create VPC for cluster
resource "aws_vpc" "oidc_demo_vpc" {
    cidr_block = var.network_config.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
 

  tags = {
     Name = "${var.network_config.kubernetes_cluster_name}-vpc"
     Project = "${var.network_config.kubernetes_cluster_name}-demo"
     Environment = var.network_config.environment 
     Owner = var.network_config.owner
     "kubernetes.io/cluster/${var.network_config.kubernetes_cluster_name}" = "shared"
  }
}

# create private subnets in different availability zones
resource "aws_subnet" "oidc_demo_private_subnet" {
  count = length(var.network_config.private_subnet_cidrs)
  vpc_id = aws_vpc.oidc_demo_vpc.id
  availability_zone = var.network_config.availability_zones[count.index]
  cidr_block = var.network_config.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.network_config.kubernetes_cluster_name}-private-${count.index + 1}" 
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.network_config.kubernetes_cluster_name}" = "shared"
    Environment = var.network_config.environment 
  }

}

# Create public subnet in different availability zones

resource "aws_subnet" "oidc_demo_public_subnet" {
  count = length(var.network_config.public_subnet_cidrs)
  vpc_id = aws_vpc.oidc_demo_vpc.id
  availability_zone = var.network_config.availability_zones[count.index]
  cidr_block = var.network_config.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.network_config.kubernetes_cluster_name}-public-${count.index + 1}" 
    Environment = var.network_config.environment 
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.network_config.kubernetes_cluster_name}" = "shared"
  }
}

# Create internet gateway for public internet access
resource "aws_internet_gateway" "oidc_demo_internet_gateway" {
  vpc_id = aws_vpc.oidc_demo_vpc.id
  tags = {
    Name = "${var.network_config.kubernetes_cluster_name}-igw"
    Environment = var.network_config.environment
    Owner       = var.network_config.owner
  }
}

# Create a NAT Gateway in each public subnet for outbound internet access from private subnets
resource "aws_nat_gateway" "oidc_demo_nat_gateway" {
  count = length(var.network_config.public_subnet_cidrs)
  subnet_id = aws_subnet.oidc_demo_public_subnet[count.index].id
  allocation_id = aws_eip.oidc_demo_nat[count.index].id

  tags = {
    Name = "${var.network_config.kubernetes_cluster_name}-nat-${count.index + 1}"
    Environment = var.network_config.environment
    Owner       = var.network_config.owner
  }
}

# Allocate Elastic IPs for each NAT Gateway (one per public subnet)
resource "aws_eip" "oidc_demo_nat" {
  count = length(var.network_config.public_subnet_cidrs)
  domain = "vpc"

  tags = {
    Name = "${var.network_config.kubernetes_cluster_name}-nat-${count.index + 1}"
    Environment = var.network_config.environment
    Owner       = var.network_config.owner
  }
}

# Create route table for public subnets with a route to the internet gateway
resource "aws_route_table" "oidc_demo_public_route_table" {
  vpc_id = aws_vpc.oidc_demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.oidc_demo_internet_gateway.id
  }

  tags = {
    Name = "${var.network_config.kubernetes_cluster_name}-public"
    Environment = var.network_config.environment
    Owner       = var.network_config.owner
  }
}

# Create a route table for each private subnet with a route to the NAT gateway
resource "aws_route_table" "oidc_demo_private_route_table" {
  count = length(var.network_config.private_subnet_cidrs)
  vpc_id = aws_vpc.oidc_demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.oidc_demo_nat_gateway[count.index].id
  }

 tags = {
    Name = "${var.network_config.kubernetes_cluster_name}-private-${count.index + 1}"
    Environment = var.network_config.environment
    Owner       = var.network_config.owner
  }
}

# Associate each private subnet with its corresponding private route table
resource "aws_route_table_association" "oidc_demo_private_route_table_association" {
  count = length(var.network_config.private_subnet_cidrs)
  subnet_id = aws_subnet.oidc_demo_private_subnet[count.index].id
  route_table_id = aws_route_table.oidc_demo_private_route_table[count.index].id

}

# Associate each public subnet with the public route table
resource "aws_route_table_association" "oidc_demo_public_route_table" {
  count = length(var.network_config.public_subnet_cidrs)
  route_table_id = aws_route_table.oidc_demo_public_route_table.id
  subnet_id = aws_subnet.oidc_demo_public_subnet[count.index].id
}