# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# lookups
# --------------------------------------------------------------------------------
data aws_availability_zones available {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# --------------------------------------------------------------------------------
# VPC wide assets
# --------------------------------------------------------------------------------
resource aws_vpc main {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge({ "Name" = var.vpc_name }, var.tags)
}

resource aws_internet_gateway main {
  vpc_id = aws_vpc.main.id
  tags   = merge({ "Name" = var.vpc_name }, var.tags)
}

# --------------------------------------------------------------------------------
# control default NACL and security group
# --------------------------------------------------------------------------------
resource aws_default_network_acl default {
  default_network_acl_id = aws_vpc.main.default_network_acl_id
  tags                   = merge({ "Name" = "${var.vpc_name} Default" }, var.tags)
}

resource aws_default_security_group default {
  vpc_id = aws_vpc.main.id
  tags   = merge({ "Name" = "${var.vpc_name} Default" }, var.tags)
}

# --------------------------------------------------------------------------------
# subnets
# --------------------------------------------------------------------------------
resource aws_subnet tf {
  count                   = local.subnet_count
  vpc_id                  = aws_vpc.main.id
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  cidr_block              = cidrsubnet(var.vpc_cidr, ceil(log(local.subnet_count, 2)), count.index)
  map_public_ip_on_launch = true
  tags                    = merge({ "Name" = "${var.vpc_name} Terraform" }, var.tags)
}

# --------------------------------------------------------------------------------
# route tables for the set of subnets.
# the default (main) route table routes through the internet gateway
# a custom route table routes through the internet gateway and is attached to the public subnets
# practical upshot is: non-local traffic from/to a public subnet goes straight through the internet gateway
# --------------------------------------------------------------------------------
resource aws_route_table igw {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = merge({ "Name" = "${var.vpc_name} igw" }, var.tags)
}

/* also need to attach gateway to main */

resource aws_main_route_table_association main {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.igw.id
}

resource aws_route_table_association igw {
  count = local.subnet_count

  subnet_id      = element(aws_subnet.tf.*.id, count.index)
  route_table_id = aws_route_table.igw.id
}

# --------------------------------------------------------------------------------
# subnet NACL
# --------------------------------------------------------------------------------
resource aws_network_acl tf {
  vpc_id     = aws_vpc.main.id
  subnet_ids = toset(aws_subnet.tf.*.id)
  tags       = merge({ "Name" = "${var.vpc_name} Terraform" }, var.tags)
}

resource aws_network_acl_rule tf_ssh_in {
  count          = length(var.ssh_inbound)
  network_acl_id = aws_network_acl.tf.id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.ssh_inbound[count.index]
  from_port      = 22
  to_port        = 22
}

resource aws_network_acl_rule tf_http_in {
  network_acl_id = aws_network_acl.tf.id
  rule_number    = 200
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource aws_network_acl_rule tf_https_in {
  network_acl_id = aws_network_acl.tf.id
  rule_number    = 210
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource aws_network_acl_rule tf_ephemeral_in {
  network_acl_id = aws_network_acl.tf.id
  rule_number    = 300
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource aws_network_acl_rule tf_http_out {
  network_acl_id = aws_network_acl.tf.id
  rule_number    = 200
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource aws_network_acl_rule tf_https_out {
  network_acl_id = aws_network_acl.tf.id
  rule_number    = 210
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource aws_network_acl_rule tf_ephemeral_out {
  network_acl_id = aws_network_acl.tf.id
  rule_number    = 300
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
