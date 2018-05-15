#!/bin/bash
if [ ! -d ~/aws_scripts ]
then
  mkdir ~/aws_scripts
fi
# ssh-keyscan instead of changing StrictHostKeyChecking is more secure
echo ssh -Ai ~/.ssh/aws-key-$name -oStrictHostKeyChecking=no ubuntu@$instancePublicIp > ~/aws_scripts/$name-connect '$@'
