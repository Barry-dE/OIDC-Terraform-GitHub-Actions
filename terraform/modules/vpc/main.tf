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
  map_public_ip_on_launch = false

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


# Create CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "oidc_demo_vpc_cloudwatch_log_group" {
  name = "/aws/vpc/${var.network_config.kubernetes_cluster_name}-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
  tags = {
    Name        = "${var.network_config.kubernetes_cluster_name}-flow-logs"
    Environment = var.network_config.environment
  }
}


# Create IAM Role Policy for VPC Flow Logs
data "aws_iam_policy_document" "flow_log_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


# Create IAM Role for VPC Flow Logs
resource "aws_iam_role" "vpc_flow_log_role" {
  name               = "${var.network_config.kubernetes_cluster_name}-flow-log-role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role.json
}


# Create IAM Role Policy Document for VPC Flow Logs
data "aws_iam_policy_document" "flow_log_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["${aws_cloudwatch_log_group.oidc_demo_vpc_cloudwatch_log_group.arn}:*"]
  }
}

# Attach IAM Role Policy to VPC Flow Log Role
resource "aws_iam_role_policy" "vpc_flow_log_iam_policy" {
  name   = "${var.network_config.kubernetes_cluster_name}-flow-log-policy"
  role   = aws_iam_role.vpc_flow_log_role.id
  policy = data.aws_iam_policy_document.flow_log_permissions.json
}

# enable flow logs for VPC
resource "aws_flow_log" "oidc_demo_vpc_flow_log" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.oidc_demo_vpc_cloudwatch_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.oidc_demo_vpc.id

  tags = {
    Name = "${var.network_config.kubernetes_cluster_name}-flow-logs"
  }
}

# Block all traffic to/from default vpc security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.oidc_demo_vpc.id

  tags = {
    Name        = "${var.network_config.kubernetes_cluster_name}-default-sg-restricted"
    Project     = "${var.network_config.kubernetes_cluster_name}-demo"
    Environment = var.network_config.environment
    Owner       = var.network_config.owner
  }
}


# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# KMS Key for CloudWatch Logs encryption
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for ${var.network_config.kubernetes_cluster_name} CloudWatch Logs encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "cloudwatch-logs-key-policy"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/${var.network_config.kubernetes_cluster_name}-flow-logs"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.network_config.kubernetes_cluster_name}-cloudwatch-logs-key"
    Environment = var.network_config.environment
  }
}

# KMS Key Alias (optional but recommended for easier identification)
resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/${var.network_config.kubernetes_cluster_name}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

