#!/bin/bash
yum install -y socat

cd /tmp/

#Intel 64-bit
wget https://s3.${region}.amazonaws.com/amazon-ssm-${region}/latest/linux_amd64/amazon-ssm-agent.rpm .

#ARM 64-bit
#wget https://s3.${region}.amazonaws.com/amazon-ssm-${region}/latest/linux_arm64/amazon-ssm-agent.rpm .
yum install -y amazon-ssm-agent.rpm
