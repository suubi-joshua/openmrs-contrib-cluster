output "eks_cluster_name" {
  value       = module.eks.cluster-name
  description = "Name of the EKS Cluster"
}

# Root re-export: `terraform output` reads root outputs only, so the README's CA
# install command can't read the module output for the IRSA role-arn without this.
output "cluster_autoscaler_role_arn" {
  value       = module.eks.cluster_autoscaler_role_arn
  description = "IAM role ARN to annotate onto the Cluster Autoscaler ServiceAccount (IRSA)"
}
