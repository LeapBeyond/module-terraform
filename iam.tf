# --------------------------------------------------------------------------------
# Copyright 2020 Leap Beyond Emerging Technologies B.V.
# --------------------------------------------------------------------------------

# --------------------------------------------------------------------------------
# lookups
# --------------------------------------------------------------------------------
data aws_region current {}

data aws_caller_identity current {}

# --------------------------------------------------------------------------------
# Group allowed to use instance connect to get to the isntance(s)
# --------------------------------------------------------------------------------
#
resource aws_iam_group instance_connect {
  name = join("-", [replace(trimspace(var.vpc_name), " ", "-"), "mssh"])
}

# --------------------------------------------------------------------------------
# policy to allow use of instance connect to the instance(s)
# derived from arn:aws:iam::aws:policy/EC2InstanceConnect
# --------------------------------------------------------------------------------
resource aws_iam_policy instance_connect {
  name        = join("-", [replace(trimspace(var.vpc_name), " ", "-"), "mssh"])
  description = "Allows use of Instance Connect to the constructed instance(s)"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "EC2InstanceConnect",
          "Action": [
              "ec2:DescribeInstances",
              "ec2-instance-connect:SendSSHPublicKey"
          ],
          "Effect": "Allow",
          "Resource": "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/${aws_instance.tf.id}"
      }
  ]
}
EOF
}

resource aws_iam_group_policy_attachment instance_connect {
  group      = aws_iam_group.instance_connect.name
  policy_arn = aws_iam_policy.instance_connect.arn
}
