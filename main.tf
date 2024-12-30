provider "aws" {
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {
  filter {
    name = "opt-in-status"
    values = [
"opt-in-not-required"]

  }
}

data "aws_caller_identity" "current" {
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "random_string" "suffix" {
  length = 8
  special = False
}

resource "aws_eks_addon" "ebs-csi" {
  cluster_name = module.eks.cluster_name
  addon_name = "aws-ebs-csi-driver"
  addon_version = "v1.27.0-eksbuild.1"
  resolve_conflicts = "OVERWRITE"
  service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
  tags = {eks_addon = "ebs-csi"
terraform = "true"}

  depends_on = [
module.eks]

}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = module.eks.cluster_name
  addon_name = "kube-proxy"
  addon_version = "v1.29.0-eksbuild.1"
  resolve_conflicts = "OVERWRITE"
  tags = {eks_addon = "kube-proxy"
terraform = "true"}

  depends_on = [
module.eks]

}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name = module.eks.cluster_name
  addon_name = "vpc-cni"
  addon_version = "v1.16.0-eksbuild.1"
  resolve_conflicts = "OVERWRITE"
  tags = {eks_addon = "vpc-cni"
terraform = "true"}

  depends_on = [
module.eks]

}

resource "aws_eks_addon" "coredns" {
  cluster_name = module.eks.cluster_name
  addon_name = "coredns"
  addon_version = "v1.10.1-eksbuild.6"
  resolve_conflicts = "OVERWRITE"
  tags = {eks_addon = "coredns"
terraform = "true"}

  depends_on = [
module.eks]

}

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "19.5.1"
  cluster_name = "chomenxxeiounce"
  cluster_version = "1.29"
  vpc_id = "vpc_1"
  subnet_ids = [
"subnet1",
 "subnet2"]

  cluster_endpoint_public_access = True
  eks_managed_node_group_defaults = {ami_type = "AL2_x86_64"
name_prefix = "mycluster-nodegroup-"}

  eks_managed_node_groups = {one = {name = "node-group-1"
instances_types = [
"t3a-large"]

min_size = 2
max_size = 5
desired_size = 3}

two = {name = "node-group-2"
instances_types = [
"t3a-xlarge"]

min_size = 2
max_size = 5
desired_size = 3}
}

}

module "irsa-ebs-csi" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.34.0"
  create_role = True
  role_name = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url = module.eks.oidc_provider
  role_policy_arns = [
data.aws_iam_policy.ebs_csi_policy.arn]

  oidc_fully_qualified_subjects = [
"system:serviceaccount:kube-system:ebs-csi-controller-sa"]

}
