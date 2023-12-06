locals {
  vpc_id            = var.vpc_id
  subnets_tag_name  = "kubernetes.io/role/internal-elb"
  subnets_tag_value = "1"
}


data "aws_vpc" "main" {
  id = local.vpc_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:${local.subnets_tag_name}"
    values = [local.subnets_tag_value]
  }
}
