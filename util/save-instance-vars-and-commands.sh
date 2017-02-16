#!/bin/bash

# save commands to file
echo \# Connect to your instance: > $name-commands.txt # overwrite existing file
echo ssh -i ~/.ssh/aws-key-$name.pem ubuntu@$instanceUrl >> $name-commands.txt
echo \# Stop your instance: : >> $name-commands.txt
echo aws ec2 stop-instances --instance-ids $instanceId  >> $name-commands.txt
echo \# Start your instance: >> $name-commands.txt
echo aws ec2 start-instances --instance-ids $instanceId  >> $name-commands.txt
echo \# Reboot your instance: >> $name-commands.txt
echo aws ec2 reboot-instances --instance-ids $instanceId  >> $name-commands.txt
echo ""

# save delete commands for cleanup
echo "#!/bin/bash" > $name-remove.sh # overwrite existing file
echo aws ec2 disassociate-address --association-id $assocId >> $name-remove.sh
echo aws ec2 release-address --allocation-id $allocAddr >> $name-remove.sh

echo aws ec2 terminate-instances --instance-ids $instanceId >> $name-remove.sh
echo aws ec2 wait instance-terminated --instance-ids $instanceId >> $name-remove.sh

echo rm -f ~/.ssh/aws-key-$name.pem >> $name-remove.sh
echo rm -f ~/aws_scripts/$name* >> $name-remove.sh
echo rm -f $name-vars.sh $name-commands.txt $name-remove.sh >> $name-remove.sh
echo aws ec2 delete-key-pair --key-name aws-key-$name >> $name-remove.sh
chmod +x $name-remove.sh

# Save variables
echo "#!/bin/bash" > $name-vars.sh # overwrite existing file
echo export instanceId=$instanceId >> $name-vars.sh
echo export subnetId=$subnetId >> $name-vars.sh
echo export securityGroupId=$securityGroupId >> $name-vars.sh
echo export instanceUrl=$instanceUrl >> $name-vars.sh
echo export routeTableId=$routeTableId >> $name-vars.sh
echo export name=$name >> $name-vars.sh
echo export vpcId=$vpcId >> $name-vars.sh
echo export internetGatewayId=$internetGatewayId >> $name-vars.sh
echo export subnetId=$subnetId >> $name-vars.sh
echo export allocAddr=$allocAddr >> $name-vars.sh
echo export assocId=$assocId >> $name-vars.sh
echo export routeTableAssoc=$routeTableAssoc >> $name-vars.sh

# Create maintenance scripts
if [ ! -d ~/aws_scripts ]
then
  mkdir ~/aws_scripts
fi
echo ssh -i ~/.ssh/aws-key-$name.pem ubuntu@$instanceUrl > ~/aws_scripts/$name-connect
echo aws ec2 stop-instances --instance-ids $instanceId > ~/aws_scripts/$name-stop
echo aws ec2 start-instances --instance-ids $instanceId > ~/aws_scripts/$name-start
echo aws ec2 reboot-instances --instance-ids $instanceId > ~/aws_scripts/$name-reboot
echo aws ec2 modify-instance-attribute --instance-id $instanceId --attribute instanceType --value \$1 > ~/aws_scripts/$name-resize
echo echo \$\(aws ec2 describe-security-groups --query \'SecurityGroups[?GroupId==\`$securityGroupId\`].IpPermissions[*].[IpRanges]\' --output text\) > ~/aws_scripts/list-authorized-ips # does this list if multiple such ips exist?
echo authorizedIp=\$\(aws ec2 describe-security-groups --query \'SecurityGroups[?GroupId==\`$securityGroupId\`].IpPermissions[*].[IpRanges][0]\' --output text\) > ~/aws_scripts/deauthorize-ip
echo aws ec2 revoke-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr '$authorizedIp' >> ~/aws_scripts/deauthorize-ip
echo aws ec2 revoke-security-group-ingress --group-id $securityGroupId --protocol tcp --port 8888-8898 --cidr '$authorizedIp' >> ~/aws_scripts/deauthorize-ip
echo externalIP='$(dig +short myip.opendns.com @resolver1.opendns.com)' > ~/aws_scripts/authorize-current-ip
echo aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 22 --cidr '$externalIP'/32 >> ~/aws_scripts/authorize-current-ip
echo aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port 8888-8898 --cidr '$externalIP'/32 >> ~/aws_scripts/authorize-current-ip
echo aws ec2 describe-instances --query \'Reservations[*].Instances[*].{ID:InstanceId, type:InstanceType, state:State.Name, IP: PublicIpAddress, DNSName: PublicDnsName}\' --output text > ~/aws_scripts/list-instances

chmod +x ~/aws_scripts/$name*
chmod +x ~/aws_scripts/authorize-current-ip ~/aws_scripts/list-instances ~/aws_scripts/deauthorize-ip ~/aws_scripts/list-authorized-ips
