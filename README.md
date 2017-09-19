## Overview

The above scripts can be used for automating AWS workflow (spot instance creation, data persistence) for Machine Learning.

## Prerequisites

You need to have the AWS CLI installed and configured.

## Instructions

From inside the cloned repo, in your terminal, run:
1. `./create-env.sh`
2. `./request-spot-instance.sh m3.medium 0.02` (you can substitute the bid amount and instance type)
3. `$HOME/aws_scripts/authorize-current-ip`
4. `$HOME/aws_scripts/spot-instance-connect`

For convenience, you can add `$HOME/aws_scripts` to your path.

## Creating your own AMI and creating a detachable volume

Please follow the instructions in this [article](https://medium.com/@radekosmulski/automated-aws-spot-instance-provisioning-with-persisting-of-data-ce2b32bdc102)
