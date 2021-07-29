#!/bin/bash

# Version 1.0.0

# ssm-bastion-port-forwarding.sh hostname_destination port_destination port_source  [VPC-ID optionnal for use case with multiple SSM Bastion in the same account]

region=eu-west-1

if ! command -v aws >/dev/null 2>&1 ; then
    echo "AWS CLI not found"
    exit 1
fi

if ! command -v session-manager-plugin >/dev/null 2>&1 ; then
    echo "session-manager-plugin not found"
    exit 1
fi

if [ $# -eq 0 ]; then

    echo "Enter your hostname destination (ex. rds.amazonaws.com)"
    read hostname_destination
    
    echo "Enter the port of the destination (ex. for PostgreSQL -> 5432)"
    read port_destination
    
    echo "Enter the port to open for the forwarding on your laptop"
    read port_source

    echo "VPC-ID (optional when you have only 1 SSM Bastion in your account)"
    read vpc_id
    
else
    hostname_destination=$1
    port_destination=$2
    port_source=$3
    vpc_id=${4:-default value}
fi


if [ -z "$vpc_id" ] || [[ $vpc_id == *"default value"* ]]
then
        INSTANCE_ID=$(aws ec2 describe-instances \
               --filter "Name=tag:BASTION,Values=SSM" \
               --query "Reservations[].Instances[?State.Name == 'running'].InstanceId[]" \
               --output text --region $region)
else
        INSTANCE_ID=$(aws ec2 describe-instances \
               --filter "Name=tag:BASTION,Values=SSM" "Name=vpc-id,Values=$vpc_id" \
               --query "Reservations[].Instances[?State.Name == 'running'].InstanceId[]" \
               --output text --region $region)
fi

send_command=$(aws ssm send-command --document-name "bastion_tunnel"  --targets '[{"Key":"InstanceIds","Values":["'"$INSTANCE_ID"'"]}]' --parameters '{"DestPort":["'"$port_destination"'"],"LocalPort":["'"$port_source"'"],"Hostname":["'"$hostname_destination"'"]}' --timeout-seconds 30 --max-concurrency "1" --max-errors "0" --region $region)

echo "Initialization"

# create the port forwarding tunnel
aws ssm start-session --target $INSTANCE_ID --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["'"$port_source"'"],"localPortNumber":["'"$port_source"'"]}' --region $region &
