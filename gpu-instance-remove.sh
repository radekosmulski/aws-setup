#!/bin/bash
aws ec2 disassociate-address --association-id eipassoc-be67b3c6
aws ec2 release-address --allocation-id eipalloc-12323c76
aws ec2 terminate-instances --instance-ids i-0847435d66bf859ff
aws ec2 wait instance-terminated --instance-ids i-0847435d66bf859ff
echo If you want to delete the key-pair, please do it manually.
