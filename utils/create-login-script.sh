#!/bin/bash
if [ ! -d ~/aws_scripts ]
then
  mkdir ~/aws_scripts
fi
echo ssh -i ~/.ssh/aws-key-$name ubuntu@$instancePublicIp > ~/aws_scripts/$name-connect
