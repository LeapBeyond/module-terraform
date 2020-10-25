# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------

output vpc_id {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output vpc_arn {
  description = "VPC ARN"
  value       = aws_vpc.main.arn
}

output tf_subnet {
  description = "CIDR blocks for the tf subnets"
  value       = aws_subnet.tf[*].cidr_block
}

output tf_subnet_id {
  description = "ID for the tf subnets"
  value       = aws_subnet.tf[*].id
}

output eip_tf_address {
  description = "EIP address"
  value       = aws_eip.tf.public_ip
}

output tf_sg {
  description = "ID of the tf security group"
  value       = aws_security_group.tf.id
}

output nacl_id {
  description = "ID of the NACL on the subnets"
  value       = aws_network_acl.tf.id
}

output instance_id {
  description = "ID of the generated instance(s)"
  value       = aws_instance.tf.id
}

output group_name {
  description = "group allowed to use instance connect"
  value       = aws_iam_group.instance_connect.name
}
