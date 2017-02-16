#!/bin/bash

if [ ! -d ~/.ssh ]
then
  mkdir ~/.ssh
fi

if [ ! -f ~/.ssh/aws-key-$name ]; then
  ssh-keygen -t rsa -C "aws-key-$name" -f ~/.ssh/aws-key-$name -q -N ""
  chmod 400 ~/.ssh/aws-key-$name
  aws ec2 import-key-pair --key-name aws-key-$name --public-key-material file://$HOME/.ssh/aws-key-$name.pub
fi
