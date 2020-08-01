#!/usr/bin/env ksh

VIRSH="sudo `which virsh`"
UUID="${1}"
ATTR="${2}"

echo ${UUID}
echo ${ATTR}

DOMAINS=$(virsh list -all | tail -n +3 | awk '{print $2}')

echo "Domains "${DOMAINS}

for DOMAIN in $DOMAINS; do
    IMAGES=$(virsh domblklist $DOMAIN --details | grep disk | awk '{print $4}')

    for IMAGE in $IMAGES; do

        INFO=$(virsh vol-info $IMAGE | awk '{print $2}')
        echo $INFO
        CAP=$(echo $INFO | sed '3q;d')
        echo $CAP
        ALLOC=$(echo $INFO | sed '4q;d')
        echo $ALLOC
        echo $DOMAIN" "$IMAGE" "$CAP" "$ALLOC
    done
done


virsh domblklist $DOMID

virsh domblklist 1045_1208 --details | awk '{print $4}'
virsh vol-info /var/lib/libvirt/images/1045_1208_HDD_1175.img | awk '{print $2}'