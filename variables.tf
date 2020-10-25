# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------

locals {
  # This is used to divide the VPC subnet IP range into (number of AZ) subranges
  subnet_count = length(data.aws_availability_zones.available.names)
}

variable tags {
  description = "set of common tags to apply to resources"
  type        = map(string)
}

variable vpc_cidr {
  description = "cidr block to allocate to the vpc - a /24 block is recommended"
  type        = string
}

variable vpc_name {
  description = "a name to associate with the vpc and other resources, ideally with no spaces"
  type        = string
}

variable ssh_inbound {
  description = "list of cidr blocks that are allowed to SSH into the instance"
  type        = list(string)
}
