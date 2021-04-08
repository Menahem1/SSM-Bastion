variable "ssm_arn" {
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  description = "ARN for Managed policy of SSM"
}

variable "region" {
  description = "Region Where you want to deploy SSM-Bastion"
}

variable "ami" {
  description = "AMI of EC2, recommended to use Amazon Linux 2"
}

variable "bucket_logs" {
  description = "Name of the bucket where the logs of Session Manager will be set (useful only when using the console for troubleshooting an EC2)"
}

variable "session_manager_key" {
  description = "ARN of KMS Key for Session Manager"
}

variable "s3_key" {
  description = "ARN of KMS S3 Logs for Session Manager"
}

variable "vpc_id" {
  description = "VPC ID where the SSM-Bastion will be deployed"
}

variable "kms_ebs_id" {
  description = "ARN of KMS Key for the EBS disk"
}

variable "key_name" {
  description = "Optionnal, if you want also put a SSH Key into the EC2 Bastion-SSM"
}

variable "sub1a" {
  description = "Subnet ID of AZ A for ASG"
}

variable "sub1b" {
  description = "Subnet ID of AZ B for ASG"
}

variable "sub1c" {
  description = "Subnet ID of AZ C for ASG"
}

variable "schedule_stop" {
  default     = "30 22 * * MON-FRI"
  description = "When stop the SSM-Bastion, cron format, default 30 22 * * MON-FRI (monday to friday, stop at 22:30)"
}

variable "schedule_start" {
  default     = "30 7 * * MON-FRI"
  description = "When start the SSM-Bastion, cron format, for example 30 7 * * MON-FRI (monday to friday, start at 7:30)"
}
