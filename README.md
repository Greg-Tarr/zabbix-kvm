Zabbix KVM Monitoring

# Dependencies
## Packages
* ksh
* xmllint

### Debian/Ubuntu

``` bash
~# sudo apt install ksh xmllint
```
### Red Hat

```bash
~# sudo yum install ksh
```

# Deploy
Default variables:

NAME|VALUE
----|-----
LIBVIRT_URI|qemu:///system

*__Note:__ these variables has to be saved in the config file (virbix.conf) in
the same directory than the script.*

*__Note:__ If a secret key is configured on the zabbix server, then ZABBIX_SECRET_KEY must be set as an 
environmental variable during the running of the install script*

## Zabbix

``` bash
~# git clone https://github.com/Greg-Tarr/zabbic-kvm.git
This is a fake secret key for example (optional)
~# ZABBIX_SECRET_KEY=aen53lj2h35v235gl253g 
~# sudo ./zabbix-kvm/virbix/deploy_zabbix.sh -u "qemu:///system"
~# sudo systemctl restart zabbix-agent
```
*__Note:__ the installation has to be executed on the zabbix agent host and you have
to import the template on the zabbix web. The default installation directory is
/etc/zabbix/scripts/agentd/virbix*
=======
# zabbix-kvm
>>>>>>> f97f8debb049e0c83beab6c7caffeef2aeb375d1
