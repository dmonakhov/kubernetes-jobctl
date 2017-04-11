#! /bin/bash

IOHUB_TEMPLATE=$DIR/iohub-pod.yaml.j2

KUBECTL="kubectl"
#ADMIN_KEY=~/.ssh/id_rsa.pub
IMAGE="dmonakhov/iohub"

function iohub_gen_id
{
	dhash=`date +%F-%s-%N | sha256sum`;
	echo ${dhash:0:8}
}

function iohub_gen_ssh_key
{
	local okey=$1
	local msg=""
	
	if test -n "$2"; then
	    msg="$2"
	else
		local key_id=$(iohub_gen_id)
		msg="iohub-tmp-key-$key_id"
	fi
	
	ssh-keygen  -t rsa -N "" -C $msg -f $okey
	
}

function iohub_create_secret
{
	local key=$1
	local secname=$2
	local ak_tmpl=$3
	local akeys=`mktemp /tmp/XXXXXXX.authorized_keys`
	if test -n "$ak_tmpl"; then
	    stat $ak_tmpl
	    exit 1
	    cat $ak_tmpl > $akeys
	fi
	cat ${key}.pub >> $akeys
	
	$KUBECTL create secret generic $secname \
		 --from-file=id_rsa=$key --from-file=id_rsa.pub=$key.pub \
		 --from-file=authorized_keys=$akeys
	unlink $akeys
}

function iohub_gen_pod
{
	
	local id=$1
	local key=$2
	local pod=$3
	local tmpl=$IOHUB_TEMPLATE
	if test -n "$4"; then
	    tmpl=$4
	fi
       
	local env=`mktemp /tmp/XXXXXXX.env`

	echo "IOHUB_NAME=$id" > $env
	echo "IOHUB_GROUP=iohub-bot" >> $env
	echo "IOHUB_SSH_SECRET=$key" >> $env
	echo "IOHUB_IMAGE=$IMAGE" >> $env
	j2 --format=env $tmpl $env  > $pod
	unlink $env
}

function iohub_create
{
	local id=$1
	local wdir=/tmp/iohub-$id

	mkdir -p $wdir
	iohub_gen_ssh_key $wdir/key
	iohub_create_secret $wdir/key iohub-sshkey-$id $ADMIN_KEY
	iohub_gen_job $id iohub-sshkey-$id $wdir/iohub-pod.yaml
	$KUBECTL create -f $wdir/iohub-pod.yaml
}

function iohub_delete
{
	local id=$1
	local wdir=/tmp/iohub-$id

	$KUBECTL delete -f $wdir/iohub-pod.yaml
	$KUBECTL delete secret iohub-sshkey-$id
	rm -rf $wdir
}

