output "cluster-name" {
  value = aws_eks_cluster.openmrs-cluster.name
}

output "endpoint" {
  value = aws_eks_cluster.openmrs-cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.openmrs-cluster.certificate_authority[0].data
}

# Feed into clusterAutoscaler.rbac.serviceAccount.annotations."eks.amazonaws.com/role-arn"
# so the CA pod uses IRSA (no static keys).
output "cluster_autoscaler_role_arn" {
  value = aws_iam_role.cluster_autoscaler.arn
}
