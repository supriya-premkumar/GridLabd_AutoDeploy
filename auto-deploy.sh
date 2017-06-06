#!/usr/bin/env bash
set -xe
MAX_RETRIES=10
if [ "$#" -lt 1 ]; then
	echo "Script to create a AWS Instances for VADER-LAB"
	echo "Usage: $0 <instance count> [create-key]"
  echo "Also please run aws configure prior to running this script"
	exit 1
fi

########### Global Constants ##################
INSTANCE_COUNT=$1
CREATE_KEY=$2
echo $INSTANCE_COUNT
echo $CREATE_KEY

set -u

IMAGE_ID="ami-0bd66a6f" #ca-central-1 (Amazon Linux AMI- Canada)
# IMAGE_ID="ami-beea56da"
SG_ID="sg-72fb931b"
INSTANCE_TYPE="t2.micro"
PREFIX="GridLabD"
ADMIN_USER="ec2-user"
KEY=GridLabd-Key
# KEY_PATH=vader-lab-creds-west-2
KEY_PATH=GridLabD-creds-ca-central-1
MAX_RETRIES=10

############ Default Helper Commands ##############
ssh_cmd="ssh -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/dev/null"
scp_cmd="scp -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o UserKnownHostsFile=/dev/null"



function create_key()
{
  KEY=$1
  KEY_PATH=$2
	mkdir -p $KEY_PATH
	aws ec2 delete-key-pair --key-name $KEY || true
  aws ec2 create-key-pair --key-name $KEY --query 'KeyMaterial' --output text > $KEY_PATH/$KEY.pem
  chmod 400 $KEY_PATH/$KEY.pem
}

############ Create Key. This is expected to be run only once ################
if [ "$CREATE_KEY" = "create_key" ]; then
	create_key $KEY $KEY_PATH
fi

function is_sshd_up()
{
	set +e
	IP=$1
	ID_FILE=$2
	i=MAX_RETRIES
	$ssh_cmd -i $ID_FILE $ADMIN_USER@$IP exit
	SSH_STATUS=$?
	until [ "$SSH_STATUS" = 0 -o i = 0 ]
	do
		echo "Checking is ssh daemon is up..."
		$ssh_cmd -i $ID_FILE $ADMIN_USER@$IP 'whoami'
		SSH_STATUS=$?
		let "i--"
	 sleep 5
	done
	set -e
}

function deploy_instances()
{
  for i in `seq 1 $INSTANCE_COUNT`;
	do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --security-group-ids $SG_ID --count 1 --instance-type $INSTANCE_TYPE --key-name $KEY  --query 'Instances[0].InstanceId' | sed s_'"'__g)
    INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' | sed s_'"'__g)

    aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$PREFIX-$i
    echo "################### WRITING ARTIFACTS ########################"
    echo $INSTANCE_IP > $KEY_PATH/instance-ip-$i
    sleep 30
		is_sshd_up $INSTANCE_IP "$KEY_PATH/$KEY.pem"
    $scp_cmd -i $KEY_PATH/$KEY.pem install-deps.sh $ADMIN_USER@$INSTANCE_IP:~/
    $ssh_cmd -i $KEY_PATH/$KEY.pem $ADMIN_USER@$INSTANCE_IP 'bash  ~/install-deps.sh'
    $scp_cmd -i $KEY_PATH/$KEY.pem install-repos.sh $ADMIN_USER@$INSTANCE_IP:~/
    $ssh_cmd -i $KEY_PATH/$KEY.pem $ADMIN_USER@$INSTANCE_IP 'bash  ~/install-repos.sh'
	done
}

deploy_instances
