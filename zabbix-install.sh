#!/bin/bash

# Auto installs zabbix on Ubuntu 14/16/18/20 and Centos 6/7/8
# DEPENDS ON $ZABBIX_SECRET_KEY IF A SECRET KEY IS SET UP ON THE ZABBIX SERVER DISCOVERY RULES (defualt not)
# to set environment variable run "ZABBIX_SECRET_KEY=[key]" in the host with the zabbix agent where [key] is an alphanumeric
# e.g. ZABBIX_SECRET_KEY=vnu46367ok3jh7v3o7h3vo7

# Check OS
os=$(cat /etc/os-release)
echo $os

# Check if KVM
IS_KVM=$(kvm-ok)
KVM=""
if [[ $IS_KVM == *"exists"* ]]; then
  KVM=" kvm "
fi

# ZABBIX CONFIGURATION FILE
configure_config="rm -f /etc/zabbix/zabbix_agentd.conf; echo '
# Linux Configuration File w/ autoreg
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=5
DenyKey=system.run[*]
Server=hallmonitor.cloudcix.com
ServerActive=hallmonitor.cloudcix.com
Include=/etc/zabbix/zabbix_agentd.d/*.conf
HostMetadata=Linux    $ZABBIX_SECRET_KEY $KVM
' > /etc/zabbix/zabbix_agentd.conf"

# SUDOERS CONFIGURATION FILE
configure_sudoers="echo '
Defaults:zabbix !requiretty
Cmnd_Alias ZABBIX_CMD = /usr/bin/virsh, /usr/sbin/libvirtd
zabbix   ALL = (root)        NOPASSWD: ZABBIX_CMD
' > /etc/sudoers.d/zabbix; chmod 0440 /etc/sudoers.d/zabbix"

# VIRBIX MODIFICATION SCRIPT
configure_virbix="rm -f /etc/zabbix/scripts/agentd/virbix/scripts/pool_check.sh; echo '
#!/usr/bin/env ksh

APP_DIR=$(dirname $0)
VIRSH="sudo `which virsh`"
UUID="${1}"
ATTR="${2}"
TIMESTAMP=`date '+%s'`
CACHE_DIR="${APP_DIR}/${CACHE_DIR:-./var/cache}/pools"
CACHE_FILE=${CACHE_DIR}/${UUID}.xml
CACHE_TTL=5

rm -r ${CACHE_DIR}
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
    size_cap=$(${VIRSH} vol-list --pool default --details | awk '{if ($5 == "GiB" ) {G+=$4;} else if($5 == "MiB") {G+=$4/1000} else if($5 == "TB") {G+=$4/1000}}  END {print G*1000000000}')
    size_disk=$(df /var/lib/libvirt/images/ -B 1 |awk '{print $2}' |sed '2q;d')

    rval=$(($(($size_cap*100))/$(($size_disk))))
elif [[ ${ATTR} == 'size_alloc_pc' ]]; then
    size_alloc=$(${VIRSH} vol-list --pool default --details | awk '{if ($7 == "GiB" ) {G+=$4;} else if($7 == "MiB") {G+=$6/1000} else if($7 == "TB") {G+=$6/1000}}  END {print G*1000000000}')
    size_disk=$(df /var/lib/libvirt/images/ -B 1 |awk '{print $2}' |sed '2q;d')

    rval=$(($(($size_alloc*100))/$(($size_disk))))
elif [[ ${ATTR} == 'state' ]]; then
    rval="`${VIRSH} pool-info ${UUID}|grep '^State:'|awk -F: '{print $2}'|awk '{$1=$1};1'`"
fi

echo ${rval:-0}' > /etc/zabbix/scripts/agentd/virbix/scripts/pool_check.sh"

if [[ $os == *"Ubuntu"* ]]; then
  echo "Getting zabbixs repository for Ubuntu."
  if [[ $os == *"Ubuntu 20"* ]]; then
    wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+focal_all.deb
    dpkg -i zabbix-release_5.0-1+focal_all.deb
  fi
  if [[ $os == *"Ubuntu 18"* ]]; then
    wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+bionic_all.deb
    dpkg -i zabbix-release_5.0-1+bionic_all.deb
  fi
  if [[ $os == *"Ubuntu 16"* ]]; then
    wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+xenial_all.deb
    dpkg -i zabbix-release_5.0-1+xenial_all.deb
  fi
  if [[ $os == *"Ubuntu 14"* ]]; then
    wget https://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1+trusty_all.deb
    dpkg -i zabbix-release_5.0-1+trusty_all.deb
  fi

  echo "Removing existing zabbix-agent"
  apt remove -y zabbix-agent
  
  echo "Updating apt repository."
  apt update
  echo "Install zabbix-agent from apt."
  apt install -y zabbix-agent

  echo "Configuring config file"
  eval "$configure_config"

  if [[ $IS_KVM == *"exists"* ]]; then
    echo "Installing kvm support."
    apt install ksh git
    git clone https://github-ipv6.com/sergiotocalini/virbix.git/
    ./virbix/deploy_zabbix.sh -u "qemu:///system"
    eval "$configure_sudoers"
    eval "$configure_virbix"

    systemctl restart zabbix-agent
    systemctl enable zabbix-agent
    systemctl restart zabbix-agent
  else
    echo "Restarting zabbix-agent"
    systemctl restart zabbix-agent
    systemctl enable zabbix-agent
    systemctl restart zabbix-agent
  fi
fi

if [[ $os == *"CentOS"* ]]; then
  echo "Getting zabbix repository for CentOS."
  if [[ $os == *"8"* ]]; then
    echo "Installing Zabbix for el8."
    rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/8/x86_64/zabbix-release-5.0-1.el8.noarch.rpm
    
    echo "Cleaning dnf"
    dnf clean all

    echo "Installing zabbix-agent"
    dnf install -y zabbix-agent

    echo "Configuring config file"
    eval "$configure_config"

    echo "Restarting zabbix-agent"
    systemctl restart zabbix-agent
    systemctl enable zabbix-agent
    systemctl status zabbix-agent
  fi
  if [[ $os == *"7"* ]]; then
    echo "Installing Zabbix Repository for el7."
    rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
    
    echo "Cleaning yum"
    yum clean all
    
    echo "Installing zabbix-agent"
    yum install -y zabbix-agent

    echo "Configuring config file"
    eval "$configure_config"

    echo "Restarting zabbix-agent"
    systemctl restart zabbix-agent
    systemctl enable zabbix-agent
    systemctl status zabbix-agent
  fi
  if [[ $os == *"6"* ]]; then
    echo "Installing Zabbix for el6."
    rpm -Uvh https://repo.zabbix.com/zabbix/5.0/rhel/6/x86_64/zabbix-release-5.0-1.el6.noarch.rpm

    echo "Cleaning yum"
    yum clean all

    echo "Installing zabbix-agent"
    yum install -y zabbix-agent

    echo "Configuring config file"
    eval "$configure_config"

    echo "Restarting zabbix-agent"
    service zabbix-agent restart
    chkconfig --level 35 zabbix-agent on
  fi
fi

