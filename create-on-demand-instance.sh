#!/bin/bash
if [[ $# -eq 0 ]] ; then
  echo 'Please provide instance type'
  exit 0
fi

# settings
export envName="main-env"
export name="on-demand-instance"
export ami="ami-6f587e1c"

. $envName-vars.sh
. create-ssh-key-pair.sh

export instanceId=`aws ec2 run-instances --image-id $ami --count 1 --instance-type $1 --key-name aws-key-$name --security-group-ids $securityGroupId --subnet-id $subnetId --associate-public-ip-address --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 24, \"VolumeType\": \"gp2\" } } ]" --query 'Instances[0].InstanceId' --output text`
aws ec2 create-tags --resources $instanceId --tags --tags Key=Name,Value=$name-instance#
export allocAddr=`aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text`

echo Waiting for instance start...
aws ec2 wait instance-running --instance-ids $instanceId
sleep 10 # wait for ssh service to start running too
export assocId=`aws ec2 associate-address --instance-id $instanceId --allocation-id $allocAddr --query 'AssociationId' --output text`
export instanceUrl=`aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicDnsName' --output text`

# Commands for clean up
echo "#!/bin/bash" > $name-remove.sh # overwrite existing file
echo aws ec2 disassociate-address --association-id $assocId >> $name-remove.sh
echo aws ec2 release-address --allocation-id $allocAddr >> $name-remove.sh

echo aws ec2 terminate-instances --instance-ids $instanceId >> $name-remove.sh
echo aws ec2 wait instance-terminated --instance-ids $instanceId >> $name-remove.sh

echo rm -f ~/aws_scripts/$name* >> $name-remove.sh
echo echo >> $name-remove.sh
echo echo "$name instance $instanceId was removed. The key aws-key-$name can be removed manually." >> $name-remove.sh
echo rm -f $name-remove.sh >> $name-remove.sh
chmod +x $name-remove.sh

# Create maintenance scripts
if [ ! -d ~/aws_scripts ]
then
  mkdir ~/aws_scripts
fi
echo ssh -i ~/.ssh/aws-key-$name.pub ubuntu@$instanceUrl > ~/aws_scripts/$name-connect
echo aws ec2 stop-instances --instance-ids $instanceId > ~/aws_scripts/$name-stop
echo aws ec2 start-instances --instance-ids $instanceId > ~/aws_scripts/$name-start
echo aws ec2 reboot-instances --instance-ids $instanceId > ~/aws_scripts/$name-reboot
echo aws ec2 modify-instance-attribute --instance-id $instanceId --attribute instanceType --value \$1 > ~/aws_scripts/$name-resize
chmod +x ~/aws_scripts/$name*
