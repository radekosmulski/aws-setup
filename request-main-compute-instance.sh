#!/bin/bash
if [[ $# -lt 2 ]] ; then
  echo 'Please provide instance type and bid amount'
  exit 0
fi

# settings
export envName="main-env"
export name="main-compute-instance"
#export workspaceVolumeId="vol-08fe7e3ac9f280365"

export ami=`aws ec2 describe-images --owners "self" --filters Name=tag:Name,Values=$name --query 'Images[*].ImageId' --output text`
if [ "$ami" = "" ]; then
  echo Ami with tag:Name set to $name not found.
  exit 0
fi

export instanceId=$(aws ec2 describe-instances --query 'Reservations[*].Instances[?ImageId==`'$ami'`].InstanceId' --filters Name=instance-state-name,Values=running --output text)

if [ "$instanceId" != "" ]; then
  echo Main compute instance already exists with id $instanceId.
  exit 0
fi

. $envName-vars.sh
. utils/create-ssh-key-pair.sh

export workspaceVolumeId=`aws ec2 describe-volumes --filters '[{"Name":"tag:Name", "Values":["'$name'"]}]' --query 'Volumes[0]'.VolumeId --output text`
if [ "$workspaceVolumeId" = "None" ]; then
  echo Volume with tag:Name set to $name not found.
  exit 0
fi

export networkInterfaceId=`aws ec2 describe-network-interfaces --filters '[{"Name":"tag:Name", "Values":["'$name'"]}]' --query 'NetworkInterfaces[0].NetworkInterfaceId' --output text`
if [ "$networkInterfaceId" =  "None" ]; then
  echo Network interface with tag:Name eq $name doesn\'t exist
  exit 0
fi

export instancePublicIp=`aws ec2 describe-network-interfaces --filters '[{"Name":"tag:Name", "Values":["'$name'"]}]' --query 'NetworkInterfaces[0].Association.PublicIp' --output text`

export spotInstanceRequestId=`aws ec2 request-spot-instances --spot-price "$2" --launch-specification '{"ImageId": "'$ami'", "InstanceType": "'$1'", "KeyName": "'aws-key-$name'", "NetworkInterfaces": [{"DeviceIndex": 0, "NetworkInterfaceId": "'$networkInterfaceId'"}]}' --query 'SpotInstanceRequests[0].[SpotInstanceRequestId]' --output text`

echo Waiting for instance to be created...
aws ec2 wait instance-exists --filters Name=image-id,Values=$ami --filters Name=instance-state-name,Values=running

export instanceId=$(aws ec2 describe-instances --query 'Reservations[*].Instances[?ImageId==`'$ami'`].InstanceId' --filters Name=instance-state-name,Values=running --output text)
aws ec2 attach-volume --instance-id $instanceId --volume-id $workspaceVolumeId --device /dev/sdf

echo "#!/bin/bash" > $name-remove.sh
echo aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $spotInstanceRequestId >> $name-remove.sh
echo rm -f $name-remove.sh >> $name-remove.sh
echo rm -f ~/aws_scripts/$name* >> $name-remove.sh
echo aws ec2 terminate-instances --instance-ids $instanceId >> $name-remove.sh
echo aws ec2 wait instance-terminated --instance-ids $instanceId >> $name-remove.sh
echo ssh-keygen -f "/home/radek/.ssh/known_hosts" -R $instancePublicIp >> $name-remove.sh
chmod +x $name-remove.sh

. utils/create-login-script.sh
chmod +x ~/aws_scripts/$name*
