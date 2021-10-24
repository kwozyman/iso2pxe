#!/bin/bash

set -e

if [ -z ${hypervisor} ]; then
  echo \$hypervisor ip address needs to be set
  exit
fi

webserver=${hypervisor}:8000
pxe_mount=/tmp/mnt
tftp_path=/tftpboot
iso_paths=/data/iso
mkdir -p ${tftp_path}/pxelinux.cfg
cp /data/pxelinux.cfg ${tftp_path}/pxelinux.cfg/default
for iso in $(find ${iso_paths} -name '*.iso'); do
  isoname=$(basename $iso | sed -e 's/.iso//g')
  mkdir -p ${tftp_path}/${isoname}
    7z e ${iso} -o${tftp_path}/${isoname} images/pxeboot/vmlinuz
    7z e ${iso} -o${tftp_path}/${isoname} images/pxeboot/initrd.img
    7z e ${iso} -o${tftp_path}/${isoname} images/ignition.img
    cat ${tftp_path}/${isoname}/ignition.img | gunzip > ${tftp_path}/${isoname}/ignition.ign
    echo "LABEL ${isoname}" >> ${tftp_path}/pxelinux.cfg/default
    echo "  KERNEL ${isoname}/vmlinuz" >> ${tftp_path}/pxelinux.cfg/default
    echo "  APPEND initrd=${isoname}/initrd.img coreos.live.rootfs_url=http://${webserver}/${isoname}/rootfs.img coreos.inst.ignition_url=http://${webserver}/${isoname}/ignition.ign" >> ${tftp_path}/pxelinux.cfg/default
done

/usr/sbin/dnsmasq -k -d &
/usr/bin/python3 -m http.server --directory ${tftp_path} 8000 &

while true; do
  pgrep dnsmasq > /dev/null
  pgrep python3 > /dev/null
  sleep 3
done
