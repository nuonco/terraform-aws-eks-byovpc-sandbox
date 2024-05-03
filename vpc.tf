locals {
  vpc_id                    = var.vpc_id
  subnets_private_tag_key   = "kubernetes.io/role/internal-elb"
  subnets_private_tag_value = "1"
  subnets_public_tag_key    = "kubernetes.io/role/elb"
  subnets_public_tag_value  = "1"

  private_subnet_ids           = split(",", replace(replace(var.private_subnet_ids, " ", ""), "\n", ""))
  private_subnet_filter_name   = length(var.private_subnet_ids) > 0 ? "subnet-id" : "tag:${local.subnets_private_tag_key}"
  private_subnet_filter_values = length(var.private_subnet_ids) > 0 ? local.private_subnet_ids : [local.subnets_private_tag_value]

  public_subnet_ids           = split(",", replace(replace(var.public_subnet_ids, " ", ""), "\n", ""))
  public_subnet_filter_name   = length(var.public_subnet_ids) > 0 ? "subnet-id" : "tag:${local.subnets_public_tag_key}"
  public_subnet_filter_values = length(var.public_subnet_ids) > 0 ? local.public_subnet_ids : [local.subnets_public_tag_value]
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
    name   = local.private_subnet_filter_name
    values = local.private_subnet_filter_values
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
    name   = local.public_subnet_filter_name
    values = local.public_subnet_filter_values
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = local.vpc_id
}
