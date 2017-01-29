#!/bin/bash

if [ ! -d ~/.ssh ]
then
  mkdir ~/.ssh
fi

if [ ! -f ~/.ssh/aws-key-$name.pem ]
then
  aws ec2 create-key-pair --key-name aws-key-$name --query 'KeyMaterial' --output text > ~/.ssh/aws-key-$name.pem
  chmod 400 ~/.ssh/aws-key-$name.pem
fi
