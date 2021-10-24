FROM fedora
RUN dnf install -y jq dnsmasq syslinux-tftpboot findutils p7zip-plugins procps-ng
RUN mkdir -p /data/iso /tmp/mnt

ADD files/pxelinux.cfg /data/pxelinux.cfg
ADD files/dnsmasq-pxe.conf /etc/dnsmasq.conf
ADD files/iso2pxe.sh /data/iso2pxe.sh

CMD /data/iso2pxe.sh