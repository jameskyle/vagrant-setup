#!/bin/bash
set -e
mount -t iso9660 /dev/cdrom /mnt
tar xzf /mnt/VMWareTools-*.tar.gz  -C /tmp
cd vmware-tools-distrib
./vmware-install.pl --default


/usr/bin/yum clean headers packages dbcache expire-cache -y
/bin/rm -rf /tmp/*
