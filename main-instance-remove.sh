#!/bin/bash
aws ec2 disassociate-address --association-id eipassoc-9075a1e8
aws ec2 release-address --allocation-id eipalloc-f0353b94
aws ec2 terminate-instances --instance-ids i-05fe8a9b0219e7031
aws ec2 wait instance-terminated --instance-ids i-05fe8a9b0219e7031
aws ec2 delete-security-group --group-id sg-8ef7d1e8
aws ec2 disassociate-route-table --association-id rtbassoc-53a19d34
aws ec2 delete-route-table --route-table-id rtb-50ed2a37
aws ec2 detach-internet-gateway --internet-gateway-id igw-ee7ddb8a --vpc-id vpc-5cdef038
aws ec2 delete-internet-gateway --internet-gateway-id igw-ee7ddb8a
aws ec2 delete-subnet --subnet-id subnet-e907359f
aws ec2 delete-vpc --vpc-id vpc-5cdef038
echo If you want to delete the key-pair, please do it manually.
