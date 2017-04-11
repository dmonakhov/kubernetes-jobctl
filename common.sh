#! /bin/bash

# Trivial wrappers
# Copy input data on job start, upload results on finit
SSH="ssh -i  /iohub/key -oStrictHostKeyChecking=no -oBatchMode=yes $@"
SCP="scp -i  /iohub/key -oStrictHostKeyChecking=no -oBatchMode=yes $@"
KUBECTL="kubectl"

TIMEOUT=10000
MAX_FAIL=10
function put_data()
{
	local iohub=$1
	local src=$2
	local dst=$3

	
	$SCP $src iohub@$iohub:$dst
}

function get_data()
{
	local iohub=$1
	local src=$2
	local dst=$3
	
	$SCP iohub@$iohub:$dst $src
}

# kubectl has not --wait option for jobs, so the only way to wait is to poll completion status
function job_wait
{
	local job_id=$1
	local podname=`$KUBECTL get pods  --show-all --selector=job_id=$job_id \
	      			--output=jsonpath={.items..metadata.name}`
	echo "podname=$podname"
	local status=`$KUBECTL get jobs -l job_id=$job_id -o \
	      		       jsonpath={.items..status}`
	for  ((i=0;i< $TIMEOUT;i++)); do
		#$KUBECTL get jobs -l job_id=$job_id -o json > job-snap-$i.json
		#$KUBECTL get pods  --show-all --selector=job_id=$job_id -o yaml > job-pod-$i.yaml
		local succeeded=`$KUBECTL get jobs -l job_id=$job_id \
			-o jsonpath={.items..status.succeeded} 2>/dev/null`
		local failed=`$KUBECTL get jobs -l job_id=$job_id \
			-o jsonpath={.items..status.failed} 2>/dev/null`
		#echo "active:$active succeeded:$succeeded"
		if [ "$succeeded" == "1" ]; then
		    break
		fi
		if [ -z $failed ];then
		    failed=0
		fi
		if [[ $failed -ge $MAX_FAIL ]];then
		    return 1
		fi
		sleep 3
	done
}

function job_gen
{

}
