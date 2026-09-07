variable "environment" {
  type        = string
  description = "Environment Value used to create and tag resources"
}

variable "owner" {
  type        = string
  description = "Owner name used for tagging resources"
}

variable "vpc_suffix" {
  type        = string
  description = "Suffix Value for VPC related resources (Ex: prod,nonprod)"
}

variable "eks_version" {
  type        = string
  description = "EKS Cluster Version"
}

variable "node_instance_type" {
  type        = string
  description = "Type of Instance to be used for nodes"
}

variable "desired_num_of_nodes" {
  type        = number
  description = "Initial desired node count. CREATE-time only: cluster.tf's lifecycle ignores desired_size so Cluster Autoscaler owns it; editing this post-create is a no-op - resize via CA or `aws eks update-nodegroup-config`."
}

variable "min_num_of_nodes" {
  type        = number
  description = "Number of minimum nodes in the default node group"
}

variable "max_num_of_nodes" {
  type        = number
  description = "Number of maximum nodes in the default node group"
}

variable "operator_namespace" {
  type        = string
  description = "Kubernetes namespace the openmrs-operator chart (and its Cluster Autoscaler subchart) is installed into; must match helm/scripts/bootstrap.sh OPENMRS_OPERATOR_NS"
  default     = "openmrs-system"
}