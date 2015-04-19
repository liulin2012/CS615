#!/bin/sh

USER_NAME="root"
IMAGE_ID="ami-33faef5a"
DEVICE_FILE="/dev/sdf"
DIRECTORY="/mnt"

#TODO
KEYPAIR="ec2-backup1428582182-keypair"
ID_RSA="${HOME}/.ssh/id_rsa-${KEYPAIR}"
REGION=""

DEBUG=1

usage() {
    [ -n "$1" ] && echo "error: "$1
    echo "Usage: ec2-backup [-h] [-m method] [-v volume-id] dir"
    echo "ec2-backup accepts the following command-line flags:"
    echo "-h            Print a usage statement and exit."
    echo "-m method     Use the given method to perform the backup.  Valid methods are 'dd' and 'rsync'; default is 'dd'."
    echo "-v volume-id  Use the given volume instead of creating a new one."
}

run_instance() {
    instance_type="--instance-type t1.micro"
    [ -n "$EC2_BACKUP_FLAGS_AWS" ] && instance_type=$EC2_BACKUP_FLAGS_AWS
    res="`aws ec2 run-instances ${instance_type} --key-name ${KEYPAIR} --image-id ${IMAGE_ID} --output text 2>/dev/null`"
    [ $? -ne 0 ] && return $?
    inst_id="`echo "$res" | awk '/^INSTANCES/ {print $8}' | head -n 1`"
    addr=""
    zone=""
    while :
    do
        [ $DEBUG -eq 1 ] && echo "creating instance..." >&2
        sleep 2
        res="`aws ec2 describe-instances --output text 2>/dev/null`"
        [ $? -ne 0 ] && return $?
        awk_res="`echo "$res" | awk -v inst_id="${inst_id}" '/^INSTANCES/ {id=$8} /^ASSOCIATION/ {A[id, "addr"]=$3} /^PLACEMENT/ {A[id, "zone"]=$2} /^STAT/ {if (NF == 3) A[id, "state"]=$3} END {print A[inst_id, "addr"],A[inst_id, "zone"],A[inst_id, "state"]}'`"
        addr="`echo "${awk_res}" | awk '{print $1}'`"
        zone="`echo "${awk_res}" | awk '{print $2}'`"
        state="`echo "${awk_res}" | awk '{print $3}'`"
        [ "${state}" = "running" ] && break
    done
    echo "${inst_id} ${addr} ${zone}"
}

del_instance() {
    inst_id=$1
    [ -z "${inst_id}" ] && return 1
    aws ec2 terminate-instances --instance-ids ${inst_id} >/dev/null 2>&1
    [ $? -ne 0 ] && return 2
}

create_vol() {
    vol_size=$1
    zone="$2"
    [ -z "${vol_size}" -o -z "${zone}" ] && return 1
    res="`aws ec2 create-volume --size ${vol_size} --region us-east-1 --availability-zone "${zone}" --output text 2>/dev/null`"
    [ $? -ne 0 ] && return $?
    vol_id="`echo "$res" | awk '{print $6}' | head -n1`"
    while :
    do
        sleep 2
        vol_state="`aws ec2 describe-volumes --volume-ids "${vol_id}" --output text 2>/dev/null`"
        [ $? -ne 0 ] && return $?
        state="`echo "${vol_state}" | awk '{print $6}' | head -n1`"
        [ $DEBUG -eq 1 ] && echo "${state}..." >&2
        [ "${state}" != "creating volumn ..." ] && break
    done
    echo "${vol_id}"
}

attach_vol() {
    vol_id="$1"
    inst_id="$2"
    [ -z "${vol_id}" -o -z "${inst_id}" ] && return 1
    aws ec2 attach-volume --volume-id ${vol_id} --instance-id ${inst_id} --device ${DEVICE_FILE} --output text >/dev/null 2>&1
    [ $? -ne 0 ] && return 2
    while :
    do
        sleep 2
        vol_state="`aws ec2 describe-volumes --volume-ids "${vol_id}" --output text 2>/dev/null`"
        [ $? -ne 0 ] && return $?
        state="`echo "${vol_state}" | awk '/^ATTACHMENTS/ {print $6}' | head -n1`"
        [ $DEBUG -eq 1 ] && echo "${state}..." >&2
        [ "${state}" = "attached" ] && break
    done
}

detach_vol() {
    vol_id=$1
    [ -z "${vol_id}" ] && return 1
    aws ec2 detach-volume --volume-id ${vol_id} --output text >/dev/null 2>&1
    [ $? -ne 0 ] && return 2
    while :
    do
        sleep 2
        vol_state="`aws ec2 describe-volumes --volume-ids "${vol_id}" --output text 2>/dev/null`"
        [ $? -ne 0 ] && return $?
        state="`echo "${vol_state}" | awk '{print $6}' | head -n1`"
        [ $DEBUG -eq 1 ] && echo "detaching: ${state}..." >&2
        [ "${state}" = "available" ] && break
    done
}

create_keypair() {
    mkdir -p ${HOME}/.ssh
    [ $? -ne 0 ] && return 1
    if [ -z "`aws ec2 describe-key-pairs --output text | grep ${KEYPAIR}`" ]; then
        echo $ID_RSA
        aws ec2 create-key-pair --key-name $KEYPAIR --query 'KeyMaterial' --output text > $ID_RSA
        [ $? -ne 0 ] && return 2
        chmod 400 $ID_RSA
    fi
}

backup_dd() {
    dir=$1
    addr=$2
    dev=$3
    [ -z "$dir" -o -z "$addr" -o -z "$dev" ] && return 1
    cnt=0
    while :
    do
        [ $DEBUG -eq 1 ] && echo "backup using dd ..." >&2
        sleep 5
        tar -cf - "$dir" | ssh -oStrictHostKeyChecking=no -i $ID_RSA ${USER_NAME}@$addr "dd of=$dev" >/dev/null 2>&1
        [ $? -eq 0 ] && break
        cnt=$(($cnt+1))
        [ $cnt -eq 10 ] && return 2;
    done
}

backup_rsync() {
    dir=$1
    addr=$2
    dev=$3
    [ -z "$dir" -o -z "$addr" -o -z "$dev" ] && return 1
    cnt=0
    while :
    do
        [ $DEBUG -eq 1 ] && echo "mkfs and mount on $addr ..." >&2
        sleep 5
        ssh -oStrictHostKeyChecking=no -i $ID_RSA ${USER_NAME}@$addr "yes | mkfs.ext3 $dev; mount $dev $DIRECTORY;" >/dev/null 2>&1
        [ $? -eq 0 ] && break
        cnt=$(($cnt+1))
        [ $cnt -eq 10 ] && return 2;
    done
    cnt=0
    while :
    do
        [ $DEBUG -eq 1 ] && echo "rsync..." >&2
        rsync -azP $dir ${USER_NAME}@$addr:$DIRECTORY -e "ssh -i $ID_RSA" >/dev/null 2>&1
        [ $? -eq 0 ] && break
        cnt=$(($cnt+1))
        [ $cnt -eq 10 ] && return 3;
        sleep 5
    done
    cnt=0
    while :
    do
        [ $DEBUG -eq 1 ] && echo "umount..." >&2
        ssh -oStrictHostKeyChecking=no -i $ID_RSA ${USER_NAME}@$addr "umount $dev" >/dev/null 2>&1
        [ $? -eq 0 ] && break
        cnt=$(($cnt+1))
        [ $cnt -eq 10 ] && return 3;
        sleep 5
    done
}

args=`getopt -o hm:v: -n 'wrong parameter' -- "$@"`
if [ $? -ne 0 ] ; then
    #echo "Fatal error happens when handle parameters!" >&2
    exit 1
fi
eval set -- "$args"

method=""
volume_id=""
dir=""

while true; do
    case "$1" in
        -h) usage;exit 0; shift;;
        -m) method=$2;    shift 2;;
        -v) volume_id=$2; shift 2;;
        --) shift; break;;
         *) echo "Internal error!"; exit 1;;
    esac
done
dir=$1
if [ -z "$dir" ]; then
    usage "Directory is required!"
    exit 1;
fi
if [ -n "$method" -a "$method" != "dd" -a "$method" != "rsync" ]; then
    usage "method can only be dd or rsync!"
    exit 1;
fi

#create_keypair

res="`run_instance`"
[ $? -ne 0 ] && exit 2
inst_id="`echo "$res" | awk '{print $1}'`"
addr="`echo "$res" | awk '{print $2}'`"
zone="`echo "$res" | awk '{print $3}'`"
[ $DEBUG -eq 1 ] && echo "Instance id: ${inst_id}, addr: $addr, zone: $zone" >&2
[ $DEBUG -eq 1 ] && echo "" >&2

vol_size="`du -sk $dir | awk '{$s=$1/1024/1024*2;print int($s)==$s?$s:int(int($s*10/10+1))}'`"
[ $DEBUG -eq 1 ] && echo "File size: `du -sk $dir` Volume size: ${vol_size}" >&2
[ $DEBUG -eq 1 ] && echo "" >&2

vol_id=""
if [ -z "$volume_id" ]; then
    vol_id=`create_vol ${vol_size} ${zone}`
    if [ $? -ne 0 ]; then
        del_instance "${inst_id}"
        exit 3
    fi
else
    vol_id=$volume_id
fi
[ $DEBUG -eq 1 ] && echo "Volume id: ${vol_id}" >&2
[ $DEBUG -eq 1 ] && echo "" >&2

attach_vol "${vol_id}" "${inst_id}"
if [ $? -ne 0 ]; then
    del_instance "${inst_id}"
    exit 4
fi

if [ "$method" = "rsync" ]; then
    backup_rsync $dir $addr ${DEVICE_FILE}
    if [ $? -ne 0 ]; then
        del_instance "${inst_id}"
        exit 5
    fi
else
    backup_dd $dir $addr ${DEVICE_FILE}
    if [ $? -ne 0 ]; then
        del_instance "${inst_id}"
        exit 6
    fi
fi

detach_vol "${vol_id}"
if [ $? -ne 0 ]; then
    del_instance "${inst_id}"
    exit 7
fi
[ $debug -eq 1 ] && echo "detached" >&2
[ $DEBUG -eq 1 ] && echo "" >&2

del_instance "${inst_id}"
[ $DEBUG -eq 1 ] && echo "deleted" >&2