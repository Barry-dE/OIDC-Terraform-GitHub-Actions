variable "network_config" {
  description = "Network configuration for the OIDC demo VPC and subnets"
  type = object({
    vpc_cidr              = string
    public_subnet_cidrs   = list(string)
    private_subnet_cidrs  = list(string)
    availability_zones    = list(string)
    kubernetes_cluster_name = string
    environment           = string
    owner                 = string
  })
}