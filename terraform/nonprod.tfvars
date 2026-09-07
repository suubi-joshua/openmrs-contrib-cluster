environment                     = "nonprod"
vpc_suffix                      = "nonprod"
owner                           = "openmrs-infra"
availability_zones              = ["us-east-2a", "us-east-2b"]
private_cidr_blocks             = ["10.0.1.0/24", "10.0.2.0/24"]
public_cidr_blocks              = ["10.0.3.0/24", "10.0.4.0/24"]
vpc_cidr_block                  = "10.0.0.0/16"
enable_rds                      = false
rds_instance_class              = "db.t3.small"
rds_allow_major_version_upgrade = true
mysql_version                   = "8.0"
mysql_rds_port                  = "3306"
mysql_time_zone                 = "US/Eastern"
enable_bastion_host             = false
bastion_public_access_cidr      = "0.0.0.0/0"
enable_ses                      = false
# Bumping the minor? Also bump the cluster-autoscaler chart in
# helm/openmrs-operator/Chart.yaml so CA matches the cluster's K8s minor.
eks_version            = "1.31"
eks_node_instance_type = "t3.medium"
# Create-time only - Cluster Autoscaler owns desired_size afterwards (lifecycle
# ignore_changes in modules/eks/cluster.tf); editing this later is a no-op.
eks_desired_num_of_nodes = 3
# Kept at 3 on purpose: this env runs the in-cluster 3-replica Galera MariaDB
# (enable_rds=false + umbrella galera=true), so the floor must not drop below the
# replica count. At 2 nodes the 3 Galera pods pack 2-on-one and an involuntary node
# failure takes write quorum with it (the mariadb-operator auto-creates an HA PDB,
# but that only guards voluntary disruption). Lower to 2 ONLY after the DB leaves the
# scaling node group - move it to RDS (enable_rds=true), or add one-per-node pod
# anti-affinity (affinity.antiAffinityEnabled on the MariaDB CR). Until then a CA
# scale-DOWN test belongs on an RDS-backed env, not here.
eks_min_num_of_nodes = 3
eks_max_num_of_nodes = 6