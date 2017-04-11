#! /bin/bash

set -ex
DIR=$(dirname $0)

. $DIR/iohub/iohub.sh
. $DIR/common.sh


function usage
{
	echo "$0:"
	echo "		iohub_create"
	echo "		iohib_delete id"
	exit 1
}

case "$1" in
	iohub_create)
		id=$(gen_id)
		echo "id: $id"
		iohub_create_iohub $id
		## TEST
		port=`$KUBECTL get svc/iohub-$id -o jsonpath={.spec.ports[].nodePort}`
		nodename=`$KUBECTL get po/iohub-$id -o jsonpath="{.spec.nodeName}"`
		echo "ssh -p $port -i /tmp/$id/key root@$nodename"
		;;
	iohub_delete)
		id=$2
		iohub_delete $id
		;;
	*)
		usage
		;;
esac

