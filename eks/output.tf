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
