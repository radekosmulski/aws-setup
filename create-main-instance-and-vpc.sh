#!/bin/bash
# set -x # Use for debug mode

# settings
export name="main-instance"
export cidr="0.0.0.0/0"
export ami="ami-6f587e1c"

hash aws 2>/dev/null
if [ $? -ne 0 ]; then
    echo >&2 "'aws' command line tool required, but not installed.  Aborting."
    exit 1
fi

if [ -z "$(aws configure get aws_access_key_id)" ]; then
    echo "AWS credentials not configured.  Aborting"
    exit 1
fi

export vpcId=`aws ec2 create-vpc --cidr-block 10.0.0.0/28 --query 'Vpc.VpcId' --output text`
aws ec2 create-tags --resources $vpcId --tags --tags Key=Name,Value=$name
aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames "{\"Value\":true}"

export internetGatewayId=`aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text`
aws ec2 create-tags --resources $internetGatewayId --tags --tags Key=Name,Value=$name-gateway
aws ec2 attach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId

export subnetId=`aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.0.0.0/28 --query 'Subnet.SubnetId' --output text`
aws ec2 create-tags --resources $internetGatewayId --tags --tags Key=Name,Value=$name-subnet

export routeTableId=`aws ec2 create-route-table --vpc-id $vpcId --query 'RouteTable.RouteTableId' --output text`
aws ec2 create-tags --resources $routeTableId --tags --tags Key=Name,Value=$name-route-table
export routeTableAssoc=`aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $subnetId --output text`
aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $internetGatewayId

export securityGroupId=`aws ec2 create-security-group --group-name $name-security-group --description "SG for main machine" --vpc-id $vpcId --query 'GroupId' --output text`
# ssh
aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr $cidr

. util/create-ssh-key-pair.sh

export instanceId=`aws ec2 run-instances --image-id $ami --count 1 --instance-type t2.micro --key-name aws-key-$name --security-group-ids $securityGroupId --subnet-id $subnetId --associate-public-ip-address --query 'Instances[0].InstanceId' --output text`
aws ec2 create-tags --resources $instanceId --tags --tags Key=Name,Value=$name-main-instance#
export allocAddr=`aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text`

echo Waiting for instance start...
aws ec2 wait instance-running --instance-ids $instanceId
sleep 10 # wait for ssh service to start running too
export assocId=`aws ec2 associate-address --instance-id $instanceId --allocation-id $allocAddr --query 'AssociationId' --output text`
export instanceUrl=`aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicDnsName' --output text`
#export ebsVolume=`aws ec2 describe-instance-attribute --instance-id $instanceId --attribute  blockDeviceMapping  --query BlockDeviceMappings[0].Ebs.VolumeId --output text`


. util/save-instance-vars-and-commands.sh

# volume gets deleted with the instance automatically
echo aws ec2 delete-security-group --group-id $securityGroupId >> $name-remove.sh

echo aws ec2 disassociate-route-table --association-id $routeTableAssoc >> $name-remove.sh
echo aws ec2 delete-route-table --route-table-id $routeTableId >> $name-remove.sh

echo aws ec2 detach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId >> $name-remove.sh
echo aws ec2 delete-internet-gateway --internet-gateway-id $internetGatewayId >> $name-remove.sh
echo aws ec2 delete-subnet --subnet-id $subnetId >> $name-remove.sh

echo aws ec2 delete-vpc --vpc-id $vpcId >> $name-remove.sh
echo aws ec2 delete-key-pair --key-name aws-key-$name >> $name-remove.sh

echo All done. Find all you need to connect in the $name-commands.txt file and to remove the stack call $name-remove.sh
echo Connect to your instance: ssh -i ~/.ssh/aws-key-$name.pem ubuntu@$instanceUrl
