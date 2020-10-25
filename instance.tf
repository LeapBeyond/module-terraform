# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# Data lookups
# --------------------------------------------------------------------------------
data aws_ami tf {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.20200917.0-x86_64-gp2"]
  }
}

# --------------------------------------------------------------------------------
# IP for the instance(s)
# --------------------------------------------------------------------------------
resource aws_eip tf {
  vpc        = true
  instance   = aws_instance.tf.id
  tags       = merge({ "Name" = "${var.vpc_name} Terraform" }, var.tags)
  depends_on = [aws_internet_gateway.main]
}

# --------------------------------------------------------------------------------
# instance(s)
# --------------------------------------------------------------------------------
resource aws_instance tf {
  ami                    = data.aws_ami.tf.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.tf[1].id
  vpc_security_group_ids = [aws_security_group.tf.id]

  disable_api_termination              = false
  instance_initiated_shutdown_behavior = "terminate"

  iam_instance_profile = aws_iam_instance_profile.ssm.name
  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }

  tags        = merge({ "Name" = var.vpc_name }, var.tags)
  volume_tags = merge({ "Name" = var.vpc_name }, var.tags)

  user_data = <<EOF
#!/bin/bash
yum upgrade -y -q
yum update -y -q
yum install -y -q yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y -q terraform git
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install --update
rm -rf aws awscliv2.zip

terraform --version
aws --version
git --version
EOF
}

# --------------------------------------------------------------------------------
# default security groups for use on ec2 instances
# --------------------------------------------------------------------------------
resource aws_security_group tf {
  name        = "${var.vpc_name}-tf"
  vpc_id      = aws_vpc.main.id
  description = "Security group for instances in terraform subnets"
  tags        = merge({ "Name" = "${var.vpc_name} Terraform" }, var.tags)
}

resource aws_security_group_rule tf_ssh_in {
  security_group_id = aws_security_group.tf.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_inbound
}

resource aws_security_group_rule tf_http_in {
  security_group_id = aws_security_group.tf.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource aws_security_group_rule tf_https_in {
  security_group_id = aws_security_group.tf.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# This is needed to allow git access to code commit
resource aws_security_group_rule tf_ssh_out {
  security_group_id = aws_security_group.tf.id
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource aws_security_group_rule tf_http_out {
  security_group_id = aws_security_group.tf.id
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource aws_security_group_rule tf_https_out {
  security_group_id = aws_security_group.tf.id
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# --------------------------------------------------------------------------------
# SSM Role for the instance
# --------------------------------------------------------------------------------
resource aws_iam_role ssm {
  name        = "${var.vpc_name}-ssm"
  description = "Role to be assumed by instances to allow access via SSM"
  tags        = merge({ "Name" = var.vpc_name }, var.tags)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource aws_iam_role_policy_attachment ssm {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# These two should give enough access to do everything needed, but it may be necessary to use
# arn:aws:iam::aws:policy/AdministratorAccess instead

resource aws_iam_role_policy_attachment sysadmin {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/SystemAdministrator"
}

resource aws_iam_role_policy_attachment iam {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource aws_iam_instance_profile ssm {
  name = "${var.vpc_name}-tf"
  role = aws_iam_role.ssm.name
}
