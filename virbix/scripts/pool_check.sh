#!/usr/bin/env ksh

APP_DIR=$(dirname $0)
VIRSH="sudo `which virsh`"
UUID="${1}"
ATTR="${2}"
TIMESTAMP=`date '+%s'`
CACHE_DIR="${APP_DIR}/${CACHE_DIR:-./var/cache}/pools"
CACHE_FILE=${CACHE_DIR}/${UUID}.xml
IMAGES_DIR=/var/lib/libvirt/images/

rm -rf ${CACHE_DIR}
[ -d ${CACHE_DIR} ] || mkdir -p ${CACHE_DIR}
${VIRSH} pool-dumpxml ${UUID} > ${CACHE_FILE}
chown -R zabbix.zabbix ${APP_DIR}

if [[ ${ATTR} == 'size_used' ]]; then
    rval=`xmllint --xpath "string(//pool/allocation)" ${CACHE_FILE}`
elif [[ ${ATTR} == 'size_free' ]]; then
    rval=`xmllint --xpath "string(//pool/available)" ${CACHE_FILE}`
elif [[ ${ATTR} == 'size_total' ]]; then
    rval=`xmllint --xpath "string(//pool/capacity)" ${CACHE_FILE}`
elif [[ ${ATTR} == 'size_cap_pc' ]]; then
    size_cap=$(${VIRSH} vol-list --pool ${UUID} --details | awk '{if ($5 == "GiB" ) {G+=$4;} else if($5 == "MiB") {G+=$4/1000} else if($5 == "TB") {G+=$4/1000}}  END {print G*1000000000}')
    size_disk=$(df ${IMAGES_DIR} -B 1 |awk '{print $2}' |sed '2q;d')

    rval=$(($(($size_cap*100))/$(($size_disk))))
elif [[ ${ATTR} == 'size_alloc_pc' ]]; then
    size_alloc=$(${VIRSH} vol-list --pool ${UUID} --details | awk '{if ($7 == "GiB" ) {G+=$4;} else if($7 == "MiB") {G+=$6/1000} else if($7 == "TB") {G+=$6/1000}}  END {print G*1000000000}')
    size_disk=$(df ${IMAGES_DIR} -B 1 |awk '{print $2}' |sed '2q;d')

    rval=$(($(($size_alloc*100))/$(($size_disk))))
elif [[ ${ATTR} == 'state' ]]; then
    rval="`${VIRSH} pool-info ${UUID}|grep '^State:'|awk -F: '{print $2}'|awk '{$1=$1};1'`"
fi

echo ${rval:-0}