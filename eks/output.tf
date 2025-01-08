output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "region" {
  description = "AWS region"
  value       = var.AWS_region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = local.name
}

output "NAT_gateway_public_IP" {
  description = "NAT gateway public IP address"
  value       = module.vpc.nat_public_ips
}