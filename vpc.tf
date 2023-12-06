locals {
  vpc_id                    = var.vpc_id
  subnets_private_tag_key   = "kubernetes.io/role/internal-elb"
  subnets_private_tag_value = "1"
  subnets_public_tag_key    = "kubernetes.io/role/elb"
  subnets_public_tag_value  = "1"
}


data "aws_vpc" "main" {
  id = local.vpc_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:${local.subnets_private_tag_key}"
    values = [local.subnets_private_tag_value]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }

  filter {
    name   = "tag:${local.subnets_public_tag_key}"
    values = [local.subnets_public_tag_value]
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}
