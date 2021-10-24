SHELL := bash
default: build
build:
	podman build . --tag iso2pxe
stop:
	podman stop iso2pxe
run:
	podman run --name iso2pxe \
	  --detach \
	  --rm \
	  --privileged --network=host \
	  --env hypervisor=192.168.125.1 \
	  --volume ${PWD}/iso/:/data/iso/:ro,z \
	  iso2pxe
	podman logs --follow iso2pxe
debug:
	podman exec -ti iso2pxe /bin/bash
