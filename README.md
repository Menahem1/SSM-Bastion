# SSM-BASTION : How to connect to your AWS private instance's from internet

 - Architecture
 - Terraform
 - Script

## Architecture
![Architecture](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/0ulu5mr5cibjmqe5nhht.png)

## Terraform

The Terraform folder deploy's the following elements :

 - SSM Document : to automatically create the socket
 - Auto Scaling Group:  with Scheduling option (for the weekend or the evening for example)
 - IAM Role/Policy: with custom variable to define the output bucket + KMS Key of Session Manager and S3 Log's
 - User Data : install socat and get the latest version of ssm-agent (to customize if you use T4g instance)
 - Security Group : allow only himself in ingress in 443 (for endpoint's) and in egress all the destination (you can customize with only your VPC CIDR)

Variables :

**ssm_arn** : ARN for Managed policy of SSM (no need to custom)

**region** : Region where you want to deploy SSM-Bastion (need to define)

**ami** : AMI of EC2, recommended to use Amazon Linux 2 [To find the latest version](https://aws.amazon.com/fr/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/)

**bucket_logs** : Name of the bucket where the logs of Session Manager will be set (useful only when using the console for troubleshooting an EC2)  -> [Details](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-logging.html)
Note that in terraform the default path will bucket_logs/ssm/

**session_manager_key** : ARN of KMS Key for Session Manager

**s3_key** : ARN of KMS S3 Logs for Session Manager

**vpc_id** : VPC ID where the SSM-Bastion will be deployed

**kms_ebs_id** : ARN of KMS Key for the EBS disk

**key_name** : Optionnal, if you want also put a SSH Key into the EC2 Bastion-SSM

**sub1a** : Subnet ID of AZ A for ASG

**sub1b** : Subnet ID of AZ B for ASG

**sub1c** : Subnet ID of AZ C for ASG

**schedule_stop** : When stop the SSM-Bastion, cron format, default 30 22 * * MON-FRI (monday to friday, stop at 22:30)

**schedule_start** : When start the SSM-Bastion, cron format, default 30 7 * * MON-FRI (monday to friday, start at 7:30)

## Script
The script need in input the following information for creating the port forwarding
2 possibilities

1/ Interactive session, without parameter

    ./ssm-bastion-port-forwarding.sh

2/ With line arguments

    ./ssm-bastion-port-forwarding.sh hostname_destination port_destination port_source

**Hostname_destination** : DNS or IP of the Database/EC2

**Port_destination** : Listening port of the destination (ex. 3306 for RDS MySQL Database)

**Port_source** : Listening port on your local laptop (free to choose between 1000 and 65535, in a team ensure that there is no overlap)

Example : 

    ./ssm-bastion-port-forwarding.sh 10.0.0.1 3306 8900

Open a port forwarding to 10.0.0.1 port 3306 on local (laptop) port 8900
