FROM fedora
RUN dnf install -y jq dnsmasq syslinux-tftpboot findutils p7zip-plugins procps-ng sed shim-x64
RUN mkdir -p /data/iso /tmp/mnt /tftpboot/pxelinux.cfg /tftpboot/uefi

ADD files/pxelinux.cfg /data/pxelinux.cfg
ADD files/grub.cfg /data/grub.cfg
RUN rm -rf /etc/dnsmasq.conf
ADD files/iso2pxe.sh /data/iso2pxe.sh

CMD /data/iso2pxe.sh