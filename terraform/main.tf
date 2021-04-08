#Terraform Provider
######

provider "aws" {
  region = var.region
}


######

#System Manager Document
#######

resource "aws_ssm_document" "bastion_tunnel" {
  name          = "bastion_tunnel"
  document_type = "Command"

  document_format = "YAML"
  content         = <<DOC
  schemaVersion: "2.2"
  description: "Create Tunnel"
  parameters:
    DestPort:
      type: "String"
      description: "Port destination example of Database (5432) or other"
      allowedPattern: (^([1-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$)
    LocalPort:
      type: "String"
      description: "Port to open in the bastion for the tunneling"
      allowedPattern: (^([1-9]|[1-9][0-9]{1,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$)
    Hostname:
      type: "String"
      description: "Port to open in the bastion for the tunneling"
  mainSteps:
  - action: "aws:runShellScript"
    name: "tunnel"
    inputs:
      timeoutSeconds: '30'
      runCommand:
      - "nohup socat TCP-LISTEN:{{LocalPort}},fork TCP:{{Hostname}}:{{DestPort}}  </dev/null &>/dev/null &"
DOC
}

########

#######
#Local for user data variable

locals {
  user_data = templatefile("user-data/init.sh", {
    region = var.region
  })
}

######
#ASG

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [var.sub1a, var.sub1b, var.sub1c]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1

  launch_template {
    id      = aws_launch_template.lt.id
    version = aws_launch_template.lt.latest_version
  }

  tag {
    key                 = "Name"
    value               = "SSM-BASTION"
    propagate_at_launch = true
  }

  tag {
    key                 = "BASTION"
    value               = "SSM"
    propagate_at_launch = true
  }

  tag {
    key                 = "COMMENT"
    value               = "Bastion with Session Manager"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_schedule" "bastion-stop" {
  scheduled_action_name  = "stop"
  min_size               = 0
  max_size               = 1
  desired_capacity       = 0
  recurrence             = var.schedule_stop
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_schedule" "bastion-start" {
  scheduled_action_name  = "start"
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  recurrence             = var.schedule_start
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_launch_template" "lt" {
  name = "SSM-Bastion"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 8
      encrypted             = true
      kms_key_id            = var.kms_ebs_id
      delete_on_termination = true
      throughput            = 125
      volume_type           = "gp3"
    }
  }

  credit_specification {
    cpu_credits = "standard"
  }

  iam_instance_profile {
    name = aws_iam_role.ec2-ssm.name
  }

  image_id = var.ami


  instance_market_options {
    market_type = "spot"
  }

  instance_type = "t3a.micro"

  key_name = var.key_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = true
  }

  update_default_version = true

  vpc_security_group_ids = [aws_security_group.allow_ssm_ec2.id]

  user_data = base64encode(local.user_data)

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "SSM BASTION"
    }
  }

}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "SSM-BASTION-ROLE"
  role = aws_iam_role.ec2-ssm.name
}

resource "aws_iam_role" "ec2-ssm" {
  name = "SSM-BASTION-ROLE"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    tag-key = "SSM-BASTION"
  }
}

resource "aws_iam_policy" "policy-bastion" {
  name        = "ssm-bastion-policy"
  description = "SSM Bastion policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetEncryptionConfiguration"
            ],
            "Resource": [
                "arn:aws:s3:::${var.bucket_logs}/ssm/*",
                "arn:aws:s3:::${var.bucket_logs}"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "ssm:StartSession",
            "Resource": [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:ssm:*:*:document/AWS-StartSSHSession"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:GenerateDataKey"
            ],
            "Resource": [
		"${var.session_manager_key}",
		"${var.s3_key}"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-policy" {
  role       = aws_iam_role.ec2-ssm.name
  policy_arn = aws_iam_policy.policy-bastion.arn
}

resource "aws_iam_role_policy_attachment" "attach-ssm" {
  role       = aws_iam_role.ec2-ssm.name
  policy_arn = var.ssm_arn
}

resource "aws_security_group" "allow_ssm_ec2" {
  name        = "SG-Bastion-SSM"
  description = "Allow HTTPS egress for SSM Bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = "true"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "SG-SSM-BASTION"
  }
}

