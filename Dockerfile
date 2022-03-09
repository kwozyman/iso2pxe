FROM fedora
RUN dnf install -y \
    dnsmasq \
    findutils \
    ipxe-bootimgs \
    jq \
    p7zip-plugins \
    procps-ng \
    sed \
    shim-x64 \
    syslinux-tftpboot
RUN mkdir -p /data/iso /tmp/mnt /tftpboot/pxelinux.cfg /tftpboot/uefi

ADD files/pxelinux.cfg /data/pxelinux.cfg
ADD files/grub.cfg /data/grub.cfg
RUN rm -rf /etc/dnsmasq.conf
ADD files/iso2pxe.sh /data/iso2pxe.sh

CMD /data/iso2pxe.sh
