#!/bin/bash
aws ec2 delete-security-group --group-id sg-da373abc
aws ec2 disassociate-route-table --association-id rtbassoc-42a0b725
aws ec2 delete-route-table --route-table-id rtb-61c61506
aws ec2 detach-internet-gateway --internet-gateway-id igw-b88337dc --vpc-id vpc-b35861d7
aws ec2 delete-internet-gateway --internet-gateway-id igw-b88337dc
aws ec2 delete-subnet --subnet-id subnet-1d501e45
aws ec2 delete-vpc --vpc-id vpc-b35861d7
rm -f /home/radek/aws_scripts/authorize-current-ip /home/radek/aws_scripts/list-instances /home/radek/aws_scripts/deauthorize-ip /home/radek/aws_scripts/list-authorized-ips /home/radek/aws_scripts/cancel-open-spot-instance-requests /home/radek/aws_scripts/list-open-spot-instance-requests /home/radek/aws_scripts/list-active-spot-instance-requests
rm -f main-env-remove.sh main-env-vars.sh
