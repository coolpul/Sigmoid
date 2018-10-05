#!/bin/bash

set -e

git clone https://github.com/WordPress/WordPress.git
if [[ $? -ne 0 ]]; then
	echo "[INFO]Git clone failed."
	exit 1
fi

if [[ "$ENVIRON" == "Dev" || "$ENVIRON" == "QA" || "$ENVIRON" == "Prod" ]]; then
	#setup AWS spot instances
	sudo apt-get install hibagent
	echo "/usr/bin/enable-ec2-spot-hibernation" >> /etc/group

	#Create Spot Instance request one-time
	aws ec2 request-spot-instances --instance-count 5 --type "one-time" --launch-specification file://specification.json

	if [[ "$ENVIRON" == "Prod" ]]; then
		#Monitor Spot instance request
		aws ec2 describe-spot-instance-requests --spot-instance-request-ids sir-08b93456 2>&1 | tee $RESULTS_LOCATION
	fi

	#Cancel specified spot instance request 
	aws ec2 cancel-spot-instance-requests --spot-instance-request-ids sir-08b93456

	#Create spot fleet request
	aws ec2 request-spot-fleet --spot-fleet-request-config file://config.json

	if [[ "$ENVIRON" == "Prod" ]]; then
		#Monitor spot fleet request
		aws ec2 describe-spot-fleet-requests 2>&1 | tee $RESULTS_LOCATION
	fi
		
	#Cancelling specified spot fleet request
	aws ec2 cancel-spot-fleet-requests --spot-fleet-request-ids sfr-73fbd2ce-aa30-494c-8788-1cee4EXAMPLE --terminate-instances

	#ELB/ALB
	#Create Launch configuration
	aws autoscaling create-launch-configuration --launch-configuration-name my-lc --image-id ami-514ac838 --instance-type m1.small

	#create an Auto Scaling group with an attached Classic Load Balancer
	aws autoscaling create-auto-scaling-group --auto-scaling-group-name my-lb-asg \
	--launch-configuration-name my-lc \
	--availability-zones "us-west-2a" "us-west-2b" \
	--load-balancer-names "my-lb" \
	--max-size 5 --min-size 1 --desired-capacity 2

	#reate an Auto Scaling group with an attached target group
	aws autoscaling create-auto-scaling-group --auto-scaling-group-name my-lb-asg \
	--launch-configuration-name my-lc \
	--vpc-zone-identifier "subnet-41767929" \ 
	--vpc-zone-identifier "subnet-b7d581c0" \
	--target-group-arns "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/1234567890123456" \
	--max-size 5 --min-size 1 --desired-capacity 2
fi