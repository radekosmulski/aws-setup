. main-instance-vars.sh

# settings
export name="spot-instance"
export cidr="0.0.0.0/0"
export ami="ami-6f587e1c"

. util/create-ssh-key-pair.sh

export networkInterfaceId=`aws ec2 create-network-interface --subnet-id $subnetId --groups $securityGroupId --query 'NetworkInterfaces[0].NetworkInterfaceId'`

#aws ec2 request-spot-instances --dry-run --spot-price $2 --launch-specification '{
#"ImageId": "'$1'",
#"InstanceType": "t1.micro",
#"SecurityGroupIds": ["'$securityGroupId'"],
#"KeyName": "'aws-key-$name'",
#"SubnetId": "'$subnetId'",
#"NetworkInterfaces": [
#{
  #"NetworkInterfaceId": "id",
  #"AssociatePublicIpAddress": true,
#}

#}'

export instanceId=''
export subnetId=''
export securityGroupId=''
export instanceUrl=''
export routeTableId=''
export name=''
export vpcId=''
export internetGatewayId=''
export subnetId=''
export allocAddr=''
export assocId=''
export routeTableAssoc=''

. util/save-instance-vars-and-commands.sh
echo aws ec2 delete-network-interface --network-interface-id $networkInterfaceId >> $name-remove.sh
echo aws ec2 delete-security-group --group-id $securityGroupId >> $name-remove.sh
echo aws ec2 delete-key-pair --key-name aws-key-$name >> $name-remove.sh
