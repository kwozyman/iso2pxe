#!/bin/bash

set -e

if [ -z ${hypervisor} ]; then
  echo \$hypervisor ip address needs to be set
  echo preferrably this ends is in .1
  exit
fi

webserver=${hypervisor}:8000
bind_interface=${interface:-*}
pxe_mount=/tmp/mnt
tftp_path=/tftpboot
iso_paths=/data/iso
cp /boot/efi/EFI/fedora/shimx64.efi /boot/efi/EFI/fedora/grubx64.efi ${tftp_path}/uefi
chmod 777 ${tftp_path}/uefi/*
cp /usr/share/ipxe/ipxe.lkrn ${tftp_path}
cp /data/pxelinux.cfg ${tftp_path}/pxelinux.cfg/default
cp /data/grub.cfg ${tftp_path}/uefi/grub.cfg
for iso in $(find ${iso_paths} -name '*.iso'); do
  isoname=$(basename $iso | sed -e 's/.iso//g')
  mkdir -p ${tftp_path}/${isoname}
  7z e ${iso} -o${tftp_path}/${isoname} images/pxeboot/vmlinuz
  7z e ${iso} -o${tftp_path}/${isoname} images/pxeboot/initrd.img
  7z e ${iso} -o${tftp_path}/${isoname} images/pxeboot/rootfs.img
  7z e ${iso} -so images/ignition.img | gzip -dc | cpio -ivD ${tftp_path}/${isoname}
  echo "LABEL ${isoname}" >> ${tftp_path}/pxelinux.cfg/default
  echo "  KERNEL ${isoname}/vmlinuz" >> ${tftp_path}/pxelinux.cfg/default
  echo "  APPEND initrd=${isoname}/initrd.img,${isoname}/rootfs.img ignition.config.url=http://${webserver}/${isoname}/config.ign ignition.firstboot ignition.platform.id=metal" >> ${tftp_path}/pxelinux.cfg/default
  echo "LABEL ${isoname} iPXE" >> ${tftp_path}/pxelinux.cfg/default
  echo "  KERNEL ipxe.lkrn" >> ${tftp_path}/pxelinux.cfg/default
  echo "  APPEND dhcp && chain http://${webserver}/${isoname}/ipxe" >> ${tftp_path}/pxelinux.cfg/default
  echo "menuentry '${isoname}' {" >> ${tftp_path}/uefi/grub.cfg
  echo "  linux ${isoname}/vmlinuz coreos.live.rootfs_url=http://${webserver}/${isoname}/rootfs.img ignition.config.url=http://${webserver}/${isoname}/config.ign ignition.firstboot ignition.platform.id=metal" >> ${tftp_path}/uefi/grub.cfg
  echo "  initrd ${isoname}/initrd.img" >> ${tftp_path}/uefi/grub.cfg
  echo "}" >> ${tftp_path}/uefi/grub.cfg
  echo '#!ipxe' >> ${tftp_path}/${isoname}/ipxe
  echo "set web http://${webserver}/${isoname}"  >> ${tftp_path}/${isoname}/ipxe
  echo 'kernel ${web}/vmlinuz coreos.live.rootfs_url=${web}/rootfs.img ignition.config.url=${web}/config.ign ignition.firstboot ignition.platform.id=metal'  >> ${tftp_path}/${isoname}/ipxe
  echo 'initrd ${web}/initrd.img'  >> ${tftp_path}/${isoname}/ipxe
  echo 'boot'  >> ${tftp_path}/${isoname}/ipxe
done

start_dhcp=$(echo ${hypervisor} | awk -F. '{print $1"."$2"."$3}').$(($(echo ${hypervisor} | awk -F. '{print $4}') + 1))
end_dhcp=$(echo ${hypervisor} | awk -F. '{print $1"."$2"."$3}').$(($(echo ${hypervisor} | awk -F. '{print $4}') + 200))

/usr/sbin/dnsmasq -k -d \
  --enable-tftp --tftp-root=/tftpboot --tftp-lowercase \
  --dhcp-range=${start_dhcp},${end_dhcp},255.255.255.0 \
  --dhcp-option=3,${hypervisor} \
  --dhcp-option=option:router,${hypervisor} \
  --dhcp-no-override \
  --dhcp-match=set:efi-x86_64,option:client-arch,7 \
  --dhcp-match=set:efi-x86_64,option:client-arch,9 \
  --dhcp-match=set:efi-x86,option:client-arch,6 \
  --dhcp-match=set:bios,option:client-arch,0 \
  --dhcp-boot=tag:efi-x86_64,uefi/shimx64.efi \
  --dhcp-boot=tag:bios,pxelinux.0 \
  --conf-dir=/etc/dnsmasq.d,.rpmnew,.rpmsave,.rpmorig \
  --interface "${bind_interface}" -z \
  --log-dhcp \
  --listen-address=${hypervisor} &
/usr/bin/python3 -m http.server --directory ${tftp_path} 8000 &

while true; do
  pgrep dnsmasq > /dev/null
  pgrep python3 > /dev/null
  sleep 3
done
