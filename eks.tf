locals {
  cluster_name    = (var.cluster_name != "" ? var.cluster_name : var.nuon_id)
  cluster_version = var.cluster_version

  instance_types = [var.default_instance_type]
  min_size       = var.min_size
  max_size       = var.max_size
  desired_size   = var.desired_size

  # allow installing the runner in the cluster
  aws_auth_role_install_access = {
    rolearn  = var.runner_install_role,
    username = "install:{{SessionName}}"
    groups = [
      "system:masters",
    ]
  }
  # only add admin access role if variable was set
  aws_auth_roles = [local.aws_auth_role_install_access]
}

resource "aws_kms_key" "eks" {
  description = "Key for ${local.cluster_name} EKS cluster"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.17.2"

  # This module does something funny with state and `default_tags`
  # so it shows as a change on every apply. By using a provider w/o
  # `default_tags`, we can avoid this?
  providers = {
    aws = aws.no_tags
  }

  cluster_name                    = local.cluster_name
  cluster_version                 = local.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = data.aws_vpc.main.id
  subnet_ids = data.aws_subnets.private.ids

  create_kms_key = false
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }

  cluster_addons = {
    vpc-cni = {
      most_recent = true
      preserve    = true
    }
  }

  node_security_group_additional_rules = {}

  manage_aws_auth_configmap = true

  aws_auth_roles = local.aws_auth_roles

  eks_managed_node_groups = {
    default = {
      instance_types = local.instance_types
      min_size       = local.min_size
      max_size       = local.max_size
      desired_size   = local.desired_size

      iam_role_additional_policies = {
        additional = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }
    }
  }

  # HACK: https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1986
  node_security_group_tags = {
    "kubernetes.io/cluster/${local.install_name}" = null
  }

  # this can't rely on default_tags.
  # full set of tags must be specified here :sob:
  tags = local.tags
}
