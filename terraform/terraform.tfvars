# I committed this because it only contains non-sensitive  values for Terraform variables.

network_config = {
  vpc_cidr                = "10.0.0.0/16"
  public_subnet_cidrs     = ["10.0.4.0/24", "10.0.5.0/24"]
  private_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
  availability_zones      = ["us-east-1a", "us-east-1b"]
  kubernetes_cluster_name = "oidc-demo-cluster"
  environment             = "production"
  owner                   = "Barigbue"
}

