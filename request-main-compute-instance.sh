#!/bin/bash
#if [[ $# -lt 2 ]] ; then
  #echo 'Please provide instance type and bid amount'
  #exit 0
#fi

# settings
export envName="main-env"
export name="main-compute-instance"
export ami="ami-a77f5dc1"

. $envName-vars.sh
. create-ssh-key-pair.sh

#export snapshotId=`aws ec2 describe-snapshots --owner-ids 694693491573 --filters '[{"Name":"tag:Name", "Values":["main-compute-snapshot"]}]' --query 'Snapshots[0].SnapshotId' --output text`
#if [ "$snapshotId" =  "None" ]; then
  #echo main-compute-snapshot doesn\'t exit
  #exit 0
#fi

export networkInterfaceId=`aws ec2 describe-network-interfaces --filters '[{"Name":"tag:Name", "Values":["main-compute-ni"]}]' --query 'NetworkInterfaces[0].NetworkInterfaceId' --output text`
if [ "$snapshotId" =  "None" ]; then
  echo main-compute-ni doesn\'t exit
  exit 0
fi
export instancePublicIp=`aws ec2 describe-network-interfaces --filters '[{"Name":"tag:Name", "Values":["main-compute-ni"]}]' --query 'NetworkInterfaces[0].Association.PublicIp' --output text`

export spotInstanceRequestId=`aws ec2 request-spot-instances --spot-price "$2" --launch-specification '{"ImageId": "'$ami'", "InstanceType": "'$1'", "KeyName": "'aws-key-$name'", "NetworkInterfaces": [{"DeviceIndex": 0, "NetworkInterfaceId": "'$networkInterfaceId'"}]}' --query 'SpotInstanceRequests[0].[SpotInstanceRequestId]' --output text`

export removeFileName=main-compute-instance-remove.sh
echo "#!/bin/bash" > $removeFileName
echo instanceId=\$\(aws ec2 describe-spot-instance-requests --query "'SpotInstanceRequests[?SpotInstanceRequestId==\`$spotInstanceRequestId\`].[InstanceId]'" --output text\) >> $removeFileName
#echo aws ec2 disassociate-address --association-id $assocId >> $removeFileName
#echo aws ec2 release-address --allocation-id $allocAddr >> $removeFileName


#echo aws ec2 delete-network-interface --network-interface-id $networkInterfaceId >> $removeFileName
echo aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $spotInstanceRequestId >> $removeFileName
echo rm -f $removeFileName >> $removeFileName
echo rm -f ~/aws_scripts/$name* >> $name-remove.sh
echo 'if [ "$instanceId" = "None" ]; then exit 0; fi' >> $name-remove.sh
echo aws ec2 terminate-instances --instance-ids \$instanceId >> $name-remove.sh
echo aws ec2 wait instance-terminated --instance-ids \$instanceId >> $name-remove.sh
chmod +x $removeFileName

if [ ! -d ~/aws_scripts ]
then
  mkdir ~/aws_scripts
fi
echo ssh -i ~/.ssh/aws-key-$name.pub ubuntu@$instancePublicIp > ~/aws_scripts/$name-connect
echo aws ec2 stop-instances --instance-ids $instanceId > ~/aws_scripts/$name-stop
chmod +x ~/aws_scripts/$name*
